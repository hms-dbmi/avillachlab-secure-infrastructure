#!/bin/bash
sudo yum install wget -y
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/centos/amd64/latest/amazon-cloudwatch-agent.rpm
sudo rpm -U amazon-cloudwatch-agent.rpm
sudo touch /opt/aws/amazon-cloudwatch-agent/etc/custom_config.json
echo "

{
	\"metrics\": {
		
		\"metrics_collected\": {
			\"cpu\": {
				\"measurement\": [
					\"cpu_usage_idle\",
					\"cpu_usage_user\",
					\"cpu_usage_system\"
				],
				\"metrics_collection_interval\": 300,
				\"totalcpu\": false
			},
			\"disk\": {
				\"measurement\": [
					\"used_percent\"
				],
				\"metrics_collection_interval\": 600,
				\"resources\": [
					\"*\"
				]
			},
			\"mem\": {
				\"measurement\": [
					\"mem_used_percent\",
                                        \"mem_available\",
                                        \"mem_available_percent\",
                                       \"mem_total\",
                                        \"mem_used\"
                                        
				],
				\"metrics_collection_interval\": 600
			}
		}
	},
	\"logs\":{
   \"logs_collected\":{
      \"files\":{
         \"collect_list\":[
            {
               \"file_path\":\"/var/log/secure\",
               \"log_group_name\":\"secure\",
               \"log_stream_name\":\"{instance_id} secure\"
            },
            {
               \"file_path\":\"/var/log/messages\",
               \"log_group_name\":\"messages\",
               \"log_stream_name\":\"{instance_id} messages\"
            },
						{
               \"file_path\":\"/var/log/audit/audit.log\",
               \"log_group_name\":\"audit.log\",
               \"log_stream_name\":\"{instance_id} audit.log\"
            },
						{
               \"file_path\":\"/var/log/yum.log\",
               \"log_group_name\":\"yum.log\",
               \"log_stream_name\":\"{instance_id} yum.log\"
            }
         ]
      }
		}
	}


}

" > /opt/aws/amazon-cloudwatch-agent/etc/custom_config.json
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/custom_config.json  -s

#!/bin/bash

ACTIVATIONURL='dsm://dsm.datastage.hms.harvard.edu:4120/'
MANAGERURL='https://dsm.datastage.hms.harvard.edu:443'
CURLOPTIONS='--silent --tlsv1.2'
linuxPlatform='';
isRPM='';

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo You are not running as the root user.  Please try again with root privileges.;
    logger -t You are not running as the root user.  Please try again with root privileges.;
    exit 1;
fi;

if ! type curl >/dev/null 2>&1; then
    echo "Please install CURL before running this script."
    logger -t Please install CURL before running this script
    exit 1
fi

curl $MANAGERURL/software/deploymentscript/platform/linuxdetectscriptv1/ -o /tmp/PlatformDetection $CURLOPTIONS --insecure

if [ -s /tmp/PlatformDetection ]; then
    . /tmp/PlatformDetection
else
    echo "Failed to download the agent installation support script."
    logger -t Failed to download the Deep Security Agent installation support script
    exit 1
fi

platform_detect
if [[ -z "$${linuxPlatform}" ]] || [[ -z "$${isRPM}" ]]; then
    echo Unsupported platform is detected
    logger -t Unsupported platform is detected
    exit 1
fi

echo Downloading agent package...
if [[ $isRPM == 1 ]]; then package='agent.rpm'
    else package='agent.deb'
fi
curl -H "Agent-Version-Control: on" $MANAGERURL/software/agent/$${runningPlatform}$${majorVersion}/$${archType}/$package?tenantID= -o /tmp/$package $CURLOPTIONS --insecure

echo Installing agent package...
rc=1
if [[ $isRPM == 1 && -s /tmp/agent.rpm ]]; then
    rpm -ihv /tmp/agent.rpm
    rc=$?
elif [[ -s /tmp/agent.deb ]]; then
    dpkg -i /tmp/agent.deb
    rc=$?
else
    echo Failed to download the agent package. Please make sure the package is imported in the Deep Security Manager
    logger -t Failed to download the agent package. Please make sure the package is imported in the Deep Security Manager
    exit 1
fi
if [[ $${rc} != 0 ]]; then
    echo Failed to install the agent package
    logger -t Failed to install the agent package
    exit 1
fi

echo Install the agent package successfully

sleep 15
/opt/ds_agent/dsa_control -r
/opt/ds_agent/dsa_control -a $ACTIVATIONURL "policyid:14"
# /opt/ds_agent/dsa_control -a dsm://dsm01.dbmi-datastage.local:4120/ "policyid:11"

echo "starting Splunk configuration"

useradd -r -m splunk

for i in 1 2 3 4 5; do echo "trying to download Splunk local forwarder from s3://${stack_s3_bucket}/splunk_config/splunkforwarder-8.0.4-767223ac207f-Linux-x86_64.tar" && sudo /usr/local/bin/aws --region us-east-1 s3 cp s3://${stack_s3_bucket}/splunk_config/splunkforwarder-8.0.4-767223ac207f-Linux-x86_64.tar /opt/ && break || sleep 60; done
echo "pulled Splunk tar file, extracting"

cd /opt
sudo tar -xf splunkforwarder-8.0.4-767223ac207f-Linux-x86_64.tar

echo "changing splunk permissions"
chown -R splunk:splunk splunkforwarder
echo "starting splunk UF as splunk user"
sudo -u splunk /opt/splunkforwarder/bin/splunk start --accept-license --answer-yes --no-prompt
echo "stopping service again to enable boot-start"
sudo -u splunk /opt/splunkforwarder/bin/splunk stop
echo "enabling boot-start"
sudo /opt/splunkforwarder/bin/splunk enable boot-start -systemd-managed 1 -user splunk

echo "Configuring inputs and outputs"

echo "
[default]
host = $(curl http://169.254.169.254/latest/meta-data/instance-id)
[monitor:///var/log/hpds-docker-logs]
sourcetype = hms_app_logs
source = hpds_logs
index=aws_main_prod
" > /opt/splunkforwarder/etc/system/local/inputs.conf

echo "updating permissions for app logs using ACL"
mkdir -p /var/log/hpds-docker-logs
sudo setfacl -R -m g:splunk:rx /var/log/hpds-docker-logs

echo "starting splunk as a service"
sudo systemctl start SplunkForwarder

echo "completed Splunk configuration"

for i in 1 2 3 4 5; do sudo /usr/local/bin/aws --region us-east-1 s3 cp s3://${stack_s3_bucket}/releases/jenkins_pipeline_build_${stack_githash}/pic-sure-hpds.tar.gz /home/centos/pic-sure-hpds.tar.gz && break || sleep 45; done
mkdir -p /opt/local/hpds/all
for i in 1 2 3 4 5; do sudo /usr/local/bin/aws --region us-east-1 s3 cp s3://${stack_s3_bucket}/data/${dataset_s3_object_key}/javabins_rekeyed.tar.gz /opt/local/hpds/javabins_rekeyed.tar.gz  && break || sleep 45; done
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/chr0masks.bin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/chr1masks.bin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/chr2masks.bin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/chr3masks.bin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/chr4masks.bin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/chr5masks.bin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/chr6masks.bin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/chr7masks.bin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/chr8masks.bin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/chr9masks.bin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/chr10masks.bin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/chr11masks.bin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/chr12masks.bin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/chr13masks.bin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/chr14masks.bin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/chr15masks.bin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/chr16masks.bin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/chr17masks.bin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/chr18masks.bin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/chr19masks.bin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/chr20masks.bin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/chr21masks.bin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/chr22masks.bin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/BucketIndexBySample.javabin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/Gene_with_variant_infoStore.javabin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/Variant_class_infoStore.javabin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/Variant_consequence_calculated_infoStore.javabin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/Variant_frequency_as_text_infoStore.javabin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/Variant_frequency_in_gnomAD_infoStore.javabin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/Variant_severity_infoStore.javabin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/BucketIndexBySampleStorage.javabin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/Gene_with_variant_infoStoreStorage.javabin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/Variant_class_infoStoreStorage.javabin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/Variant_consequence_calculated_infoStoreStorage.javabin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/Variant_frequency_as_text_infoStoreStorage.javabin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/Variant_frequency_in_gnomAD_infoStoreStorage.javabin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/Variant_severity_infoStoreStorage.javabin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/variantIndex.javabin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/variantIndex_decompressed.javabin /opt/local/hpds/all/
aws s3 cp s3://${stack_s3_bucket}/data/${genomic_dataset_s3_object_key}/all/variantStore.javabin /opt/local/hpds/all/

cd /opt/local/hpds
tar -xvzf javabins_rekeyed.tar.gz
cd ~

for i in 1 2 3 4 5; do sudo /usr/local/bin/aws --region us-east-1 s3 cp s3://${stack_s3_bucket}/domain-join.sh /root/domain-join.sh && break || sleep 45; done
sudo bash /root/domain-join.sh

sudo mkdir -p /var/log/hpds-docker-logs

HPDS_IMAGE=`sudo docker load < /home/centos/pic-sure-hpds.tar.gz | cut -d ' ' -f 3`
sudo docker run --restart unless-stopped --name=hpds -v /opt/local/hpds:/opt/local/hpds -p 8080:8080 --entrypoint=java -d $HPDS_IMAGE -XX:+UseParallelGC -XX:SurvivorRatio=250 -Xms10g -Xmx110g -server -jar hpds.jar -httpPort 8080 -DCACHE_SIZE=2500 -DSMALL_TASK_THREADS=1 -DLARGE_TASK_THREADS=1 -DSMALL_JOB_LIMIT=100 -DID_BATCH_SIZE=5000 "-DALL_IDS_CONCEPT=NONE"  "-DID_CUBE_NAME=NONE"

sudo docker logs -f hpds > /var/log/hpds-docker-logs/hpds.log &

INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")" --silent http://169.254.169.254/latest/meta-data/instance-id)
sudo /usr/local/bin/aws --region=us-east-1 ec2 create-tags --resources $${INSTANCE_ID} --tags Key=InitComplete,Value=true

