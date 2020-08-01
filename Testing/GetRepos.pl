#!/usr/local/bin/perl

require FreshPorts::branches;

# get the repo names for each of the repos

my @repos = ('ports', 'ports-quarterly');

my $REPODIR;
my $REPODIR_CHROOT;


foreach my $repo (@repos) {
    $REPODIR        = FreshPorts::Branches::GetPathToRepoForBranch      ($repo, '');
    $REPODIR_CHROOT = FreshPorts::Branches::GetPathToRepoForBranchCHROOT($repo, '');
    
    print "$repo has REPODIR='$REPODIR' and REPODIR_CHROOT='$REPODIR_CHROOT'\n";
}