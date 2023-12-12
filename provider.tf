# Define provider (AWS in this case)
provider "aws" {  # In the real case senario, the version constraint for provider "AWS" will be required here
  region = "eu-west-1" # This could be changed to your preferred AWS region
}