# Project overview, in plain English

I'm putting a notes app (memos) on the internet at eks.abdijalil.dev, using the same
tools a real company would. Everything is built from written instructions instead of
by clicking around in AWS, so I can rebuild or delete the whole thing in minutes.

## Step 1 - Setting up
I created a home for the project (a GitHub repo) with folders for each kind of work.
I reused a website domain I already own and added a new address under it.

## Step 2 - Running the app on my laptop
Before anything else, I made sure the app worked on my own computer. I learned the app
has to be assembled in a certain order, the way a house needs a frame before walls.

## Step 3 - Giving the app a real database
The app can store notes in a simple file or in a proper database (Postgres). I chose
the database because real systems have several parts that talk to each other. I checked
that notes survive restarting the app.

## Step 4 - Packaging the app
I packaged the app into a sealed box (a Docker image) that runs the same way on any
computer. My first attempt broke because the box was missing some files, and a small
extra tool was needed for the type of Linux it uses. Once fixed, it worked.

## Step 5 - Storing the package in AWS
I uploaded the package to AWS's storage for these packages (ECR). Each upload is labeled
with a code that matches the exact version of my work, so I always know what's running.

## Step 6 - A safe place for Terraform's notebook
Terraform is the tool that builds my AWS setup from written instructions. It keeps a
notebook of what it has built. I made a protected storage bucket for that notebook by
hand, because it has to exist before Terraform can start.

## Step 7 - Building the foundations with Terraform
- Network (VPC): a private network in AWS with public sections (visitors can reach them)
  and private sections (where the app's computers live, hidden from the internet). A
  single one-way door lets private computers reach out to the internet, such as to
  download things, without letting anyone in.
- Permissions (IAM): two badges, one for the cluster's manager and one for its worker
  computers, each allowed to do only what it needs.
- Firewall (security group): a guest list for the worker computers. It lets in traffic
  from the load balancer, the part that passes visitors on to the app, and nothing else.
- The cluster (EKS): the cluster is a manager that decides which computer runs which
  part of the app, and three worker computers in three separate data centers so one
  failure doesn't take everything down.
- Wiring: a main file connects all four pieces, passing each one's results to the next.

I ran it by hand first to see it work: 30 pieces were built, all three workers came
online, then I deleted everything to avoid paying for it while I wasn't using it.

## Step 8 - Installing ArgoCD
ArgoCD is a robot that watches my project folder and makes the cluster match whatever
is written there. Terraform installs it, and from then on ArgoCD takes over.

## Step 9 - Getting the passwords ready
The app's database needs a password, and a password must never be saved in the project
folder, because the folder keeps every old version forever. So the password will live in
a locked AWS safe, and a helper inside the cluster will fetch it and hand it to the
database.

For AWS to let the helper into the safe, the cluster has to be registered as a place AWS
trusts to hand out ID badges. I set that up, and built a badge for the helper that only
lets it read the one password and nothing else.

I also created the app's own section of the cluster (a namespace), where the app and its
database will live together.

