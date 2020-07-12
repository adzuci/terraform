# Terraform

This repo contains the modules and plans that I have used to spin up resources in AWS.

# Contributing

## Get an AWS account

https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account/

## Install Requirements

```
brew install awscli terraform warrensbox/tap/tfswitch
```

Note: This README is macOS specific, feel free to submit a PR with Linux instructions.

## Editors

If you're new to working with terraform you ay want to install an IDE that supports terraform linting

e.g.
```
brew install visual-studio-code
code --install-extensions hashicorp.terraform
```
or
```
brew cask install sublime-text
mkdir ~/.config/sublime-text-3/Installed\ Packages
curl https://packagecontrol.io/Package%20Control.sublime-package > ~/Library/Application\ Support/Sublime\ Text\ 3/Installed\ Packages/Package\ Control.sublime-package
cat << EOF > ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/Package\ Control.sublime-settings
{
    "installed_packages":
    [
        "Package Control",
        "Python Flake8 Lint",
        "Python Improved",
        "SideBarGit",
        "SublimeLinter-contrib-terraform",
		"Terrafmt"
    ]
}
EOF
```

## Initializing

1. Update `plans/dyhedral/aws.tf` and `plans/dyhedral/terraform.tfvars` to reference the correct account information and comment out the `backend "s3"` block.
2. Log into AWS with `aws configure` by entering your AWS access key and secret (warning, this will store your keys in a file)
3. Run `terraform init`.

## Creating The VPC

1. Run `terraform plan -target=module.vpc`
2. Run `terraform apply -target=module.vpc` enter "yes".
3. Populate `vpc_id`, `eks_internet_gateway` & `aws_account_id` in `plans/dyhedral/terraform.tfvars`.

## Creating Everything Else 

1. Run `terraform plan`
2. Run `terraform apply`
