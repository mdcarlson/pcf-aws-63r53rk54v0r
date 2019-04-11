resource "aws_instance" "ops_manager" {
  ami                    = "${var.ami}"
  instance_type          = "${var.instance_type}"
  key_name               = "${aws_key_pair.ops_manager.key_name}"
  vpc_security_group_ids = ["${aws_security_group.ops_manager_security_group.id}"]
  source_dest_check      = false
  subnet_id              = "${var.subnet_id}"
  iam_instance_profile   = "${aws_iam_instance_profile.ops_manager.name}"
  count                  = "${var.vm_count}"

  root_block_device {
    volume_type = "gp2"
    volume_size = 150
  }

  user_data = <<-EOF
                  #!/bin/bash
                  mkdir /tmp/ssm
                  cd /tmp/ssm
                  wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
                  sudo dpkg -i amazon-ssm-agent.deb
                  EOF

  tags = "${merge(var.tags, map("Name", "${var.env_name}-ops-manager"))}"
}
