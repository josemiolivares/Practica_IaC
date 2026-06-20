output "alb_dns_name" {
  description = "DNS público del Application Load Balancer"
  value       = aws_lb.app_lb.dns_name
}
output "wordpress_url" {
  description = "URL para acceder a la aplicación WordPress"
  value       = "http://${aws_lb.app_lb.dns_name}"
}
output "rds_endpoint" {
  description = "Endpoint (DNS) de la base de datos RDS"
  value       = aws_db_instance.wordpress_db.address
}
output "alb_subnets" {
  description = "AZ con subnets públicas para el alb"
  value = aws_subnet.public[*].availability_zone
}
