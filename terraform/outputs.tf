output "public_ip"      { value = aws_instance.k3s.public_ip }
output "ssh"            { value = "ssh -i devsecops-key.pem ubuntu@${aws_instance.k3s.public_ip}" }
output "app_url"        { value = "http://${aws_instance.k3s.public_ip}:30080" }
output "reports_bucket" { value = aws_s3_bucket.reports.bucket }
