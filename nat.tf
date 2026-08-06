resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.eks_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id = aws_subnet.public[0].id

  tags = {
    Name = "${var.eks_name}-nat"
  }

  depends_on = [aws_internet_gateway.igw]
}