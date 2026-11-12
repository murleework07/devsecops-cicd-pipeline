# S3 bucket for security scan reports
resource "aws_s3_bucket" "reports" {
  bucket        = "${var.project}-scan-reports-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "reports" {
  bucket = aws_s3_bucket.reports.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "reports" {
  bucket                  = aws_s3_bucket.reports.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Least-privilege IAM user for Jenkins: can ONLY upload into this bucket
resource "aws_iam_user" "jenkins" {
  name = "${var.project}-jenkins-uploader"
}

resource "aws_iam_user_policy" "jenkins" {
  name = "s3-put-reports-only"
  user = aws_iam_user.jenkins.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "s3:PutObject"
      Resource = "${aws_s3_bucket.reports.arn}/*"
    }]
  })
}

# EC2 role: only what Session Manager needs
resource "aws_iam_role" "k3s" {
  name = "${var.project}-k3s-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.k3s.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "k3s" {
  name = "${var.project}-k3s-profile"
  role = aws_iam_role.k3s.name
}
