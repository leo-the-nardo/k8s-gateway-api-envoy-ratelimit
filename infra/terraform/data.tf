# Data sources for AWS availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.us_east_1
}
