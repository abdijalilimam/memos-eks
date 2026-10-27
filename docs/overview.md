# Project overview

I'm putting a notes app (memos) on the internet at eks.abdijalil.dev, using the same tools
a real company would. Everything is built from written instructions instead of by clicking
around in AWS, so I can rebuild or delete the whole thing in minutes.

## Step 1 - Setting up
I created a home for the project (a GitHub repo) with a folder for each kind of work. I
reused a website domain I already own and added a new address under it.

## Step 2 - Running the app on my laptop
I made sure the app worked on my own computer first. It has to be assembled in a certain
order, the way a house needs a frame before walls.

## Step 3 - Giving the app a real database
I chose a proper database (Postgres) over a simple file, because real systems have several
parts that talk to each other. I checked that notes survive restarting the app.

## Step 4 - Packaging the app
I packaged the app into a sealed box (a Docker image) that runs the same way on any
computer. My first attempt broke because the box was missing some files and one small tool.

## Step 5 - Storing the package in AWS
I uploaded the package to AWS's storage for these (ECR). Each upload is labeled with a code
that matches the exact version of my work, so I always know what's running.

## Step 6 - A safe place for Terraform's notebook
Terraform is the tool that builds my AWS setup from written instructions, and it keeps a
notebook of what it has built. I made a protected storage bucket for that notebook by hand,
because it has to exist before Terraform can start.

## Step 7 - Building the foundations with Terraform
I built the private network, two ID badges (one for the cluster's manager and one for its
worker computers), a firewall for the workers, and the cluster itself, which is a manager
plus three workers in three separate data centers. I ran it by hand to see it work: 30
pieces were built and all three workers came online, then I deleted everything to avoid
paying for it.

## Step 8 - Installing ArgoCD
ArgoCD is a robot that watches my project folder and makes the cluster match whatever is
written there. Terraform installs it, and from then on ArgoCD takes over.

## Step 9 - Getting the passwords ready
A password must never be saved in the project folder, because the folder keeps every old
version forever. So the password will live in a locked AWS safe, and a helper inside the
cluster will fetch it for the database. I registered the cluster with AWS as a place it
trusts to hand out ID badges, built a badge for that helper that only lets it read the one
password, and created the app's own section of the cluster (a namespace).

## Step 10 - A place for the database's data, and a badge for the address helper
When a piece of the app restarts, anything stored inside it is wiped, so the database gets
a separate, permanent disk from AWS. I added the small program that orders those disks,
and a badge for the helper that creates the website address, allowed to edit my domain's
records and nothing else. None of this is built in AWS yet. It gets created the next time I
turn the cluster on.