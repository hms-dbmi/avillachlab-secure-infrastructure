variable "stack_githash" {
  type = string
}
variable "stack_githash_long" {
  type = string
}

variable "target-stack" {
  description = "The stack identifier"
  type        = string
}

variable "dataset-s3-object-key" {
  description = "The s3 object key within the environment s3 bucket"
  type        = string
}

variable "destigmatized-dataset-s3-object-key" {
  description = "The s3 object key within the environment s3 bucket"
  type        = string
}

variable "genomic-dataset-s3-object-key" {
  description = "The s3 object key within the environment s3 bucket"
  type        = string
}

resource "aws_iam_instance_profile" "wildfly-deployment-s3-profile" {
  name = "wildfly-deployment-s3-profile-${var.target-stack}-${var.stack_githash}"
  role = aws_iam_role.wildfly-deployment-s3-role.name
}

resource "aws_iam_role_policy" "wildfly-deployment-s3-policy" {
  name = "wildfly-deployment-s3-policy-${var.target-stack}-${var.stack_githash}"
  role = aws_iam_role.wildfly-deployment-s3-role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.stack_s3_bucket}/releases/jenkins_pipeline_build_${var.stack_githash_long}/pic-sure-wildfly.tar.gz"
    },
    {
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.stack_s3_bucket}/data/${var.dataset-s3-object-key}/fence_mapping.json"
    },
    {
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.stack_s3_bucket}/configs/jenkins_pipeline_build_${var.stack_githash_long}/standalone.xml"
    },
    {
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.stack_s3_bucket}/configs/jenkins_pipeline_build_${var.stack_githash_long}/pic-sure-schema.sql"
    },
    {
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.stack_s3_bucket}/configs/jenkins_pipeline_build_${var.stack_githash_long}/aggregate-resource.properties"
    },{
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.stack_s3_bucket}/modules/*"
    },
    {
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.stack_s3_bucket}/domain-join.sh"
    },
    {
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.stack_s3_bucket}/splunk_config/splunkforwarder-8.0.4-767223ac207f-Linux-x86_64.tar"
    },
    {
      "Action": [
        "ec2:CreateTags"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:ec2:*:*:instance/*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "wildfly-deployment-s3-role" {
  name               = "wildfly-deployment-s3-role-${var.target-stack}-${var.stack_githash}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach-cloudwatch-server-policy-to-wildfly-role" {
  role       = aws_iam_role.wildfly-deployment-s3-role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
resource "aws_iam_role_policy_attachment" "attach-cloudwatch-ssm-policy-to-wildfly-role" {
  role       = aws_iam_role.wildfly-deployment-s3-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_iam_instance_profile" "httpd-deployment-s3-profile" {
  name = "httpd-deployment-s3-profile-${var.target-stack}-${var.stack_githash}"
  role = aws_iam_role.httpd-deployment-s3-role.name
}

resource "aws_iam_role_policy" "httpd-deployment-s3-policy" {
  name = "httpd-deployment-s3-policy-${var.target-stack}-${var.stack_githash}"
  role = aws_iam_role.httpd-deployment-s3-role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.stack_s3_bucket}/releases/jenkins_pipeline_build_${var.stack_githash_long}/pic-sure-ui.tar.gz"
    },{
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.stack_s3_bucket}/certs/httpd/server.crt"
    },{
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.stack_s3_bucket}/certs/httpd/server.chain"
    },{
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.stack_s3_bucket}/certs/httpd/server.key"
    },{
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.stack_s3_bucket}/certs/httpd/preprod_server.crt"
    },{
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.stack_s3_bucket}/certs/httpd/preprod_server.chain"
    },{
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.stack_s3_bucket}/certs/httpd/preprod_server.key"
    },{
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.stack_s3_bucket}/configs/jenkins_pipeline_build_${var.stack_githash_long}/httpd-vhosts.conf"
    },{
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.stack_s3_bucket}/configs/jenkins_pipeline_build_${var.stack_githash_long}/psamaui_settings.json"
    },{
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.stack_s3_bucket}/configs/jenkins_pipeline_build_${var.stack_githash_long}/picsureui_settings.json"
    },{
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.stack_s3_bucket}/data/${var.dataset-s3-object-key}/fence_mapping.json"
    },{
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.stack_s3_bucket}/domain-join.sh"
    },
    {
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.stack_s3_bucket}/splunk_config/splunkforwarder-8.0.4-767223ac207f-Linux-x86_64.tar"
    },
    {
      "Action": [
        "ec2:CreateTags"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:ec2:*:*:instance/*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "httpd-deployment-s3-role" {
  name               = "httpd-deployment-s3-role-${var.target-stack}-${var.stack_githash}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach-cloudwatch-server-policy-to-httpd-role" {
  role       = aws_iam_role.httpd-deployment-s3-role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
resource "aws_iam_role_policy_attachment" "attach-cloudwatch-ssm-policy-to-httpd-role" {
  role       = aws_iam_role.httpd-deployment-s3-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_iam_instance_profile" "hpds-deployment-s3-profile" {
  name = "hpds-deployment-s3-profile-${var.target-stack}-${var.stack_githash}"
  role = aws_iam_role.hpds-deployment-s3-role.name
}

resource "aws_iam_role_policy" "hpds-deployment-s3-policy" {
  name = "hpds-deployment-s3-policy-${var.target-stack}-${var.stack_githash}"
  role = aws_iam_role.hpds-deployment-s3-role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.stack_s3_bucket}/releases/jenkins_pipeline_build_${var.stack_githash_long}/pic-sure-hpds.tar.gz"
    },
    {
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.stack_s3_bucket}/data/${var.destigmatized-dataset-s3-object-key}/destigmatized_javabins_rekeyed.tar.gz"
    },
    {
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.stack_s3_bucket}/data/${var.dataset-s3-object-key}/javabins_rekeyed.tar.gz"
    },
    {
       "Action": [
      "s3:GetObject"
       ],
       "Effect": "Allow",
       "Resource": "arn:aws:s3:::${var.stack_s3_bucket}/data/${var.genomic-dataset-s3-object-key}/all/*"
   },
   {
       "Action": [
      "s3:ListBucket"
       ],
       "Effect": "Allow",
       "Resource": "arn:aws:s3:::${var.stack_s3_bucket}",
       "Condition": {
      "StringLike": {
          "s3:prefix": [
         "data/${var.genomic-dataset-s3-object-key}/all*"
          ]
      }
       }
   },
    {
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.stack_s3_bucket}/configs/jenkins_pipeline_build_${var.stack_githash_long}/hpds-log4j.properties"
    },
    {
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.stack_s3_bucket}/domain-join.sh"
    },
    {
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.stack_s3_bucket}/splunk_config/splunkforwarder-8.0.4-767223ac207f-Linux-x86_64.tar"
    },
    {
      "Action": [
        "ec2:CreateTags"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:ec2:*:*:instance/*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "hpds-deployment-s3-role" {
  name               = "hpds-deployment-s3-role-${var.target-stack}-${var.stack_githash}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach-cloudwatch-server-policy-to-hpds-role" {
  role       = aws_iam_role.hpds-deployment-s3-role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
resource "aws_iam_role_policy_attachment" "attach-cloudwatch-ssm-policy-to-hpds-role" {
  role       = aws_iam_role.hpds-deployment-s3-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
