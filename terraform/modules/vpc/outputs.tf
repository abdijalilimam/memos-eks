output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = [
    aws_subnet.public_subnets["s1"].id,
    aws_subnet.public_subnets["s2"].id,
    aws_subnet.public_subnets["s3"].id,
  ]
}

output "private_subnet_ids" {
  value = [
    aws_subnet.private_subnets["s1"].id,
    aws_subnet.private_subnets["s2"].id,
    aws_subnet.private_subnets["s3"].id,
  ]
}

output "public_subnet_cidrs" {
  value = [
    aws_subnet.public_subnets["s1"].cidr_block,
    aws_subnet.public_subnets["s2"].cidr_block,
    aws_subnet.public_subnets["s3"].cidr_block,
  ]
}