#!/usr/local/bin/perl
#
# Copyright (c) 2014 DVL Software
#

package FreshPorts::Branches;

require FreshPorts::config;
require FreshPorts::constants;
require FreshPorts::utilities;

#use Switch;

# these are the mailing lists associated with those branches
%FreshPorts::Branches::MailingLists = (
  '"SVN commit messages for the entire src tree \(except for &quot;' => {
     'process' => 'process_svn_mail',
     'repo'    => $FreshPorts::Config::Repo_SRC,
     },
  '"SVN commit messages for the entire doc trees \(except for &quot;' => {
     'process' => 'process_svn_mail',
     'repo'    => $FreshPorts::Config::Repo_DOC,
     },
  '"SVN commit messages for the entire doc trees \(except for &quot; user&quot; , &quot; projects&quot; , and &quot; translations&quot; \)" <svn-doc-all.freebsd.org>' => {
     'process' => 'process_svn_mail',
     'repo'    => $FreshPorts::Config::Repo_DOC,
     },
  'SVN commit messages for the ports tree for head' => {
     'process' => 'process_svn_mail',
     'repo'    => $FreshPorts::Config::Repo_PORTS,
     },
  'SVN commit messages for the ports tree for head <svn-ports-head.freebsd.org>' => {
     'process' => 'process_svn_mail',
     'repo'    => $FreshPorts::Config::Repo_PORTS,
     },
  'SVN commit messages for all the branches of the ports tree' => {
     'process' => 'process_svn_mail',
     'repo'    => $FreshPorts::Config::Repo_PORTS,
     },
  'CVS commit messages for the ports tree' => {
     'process' => 'process_cvs_mail',
     'repo'    => '',
     },
  'CVS commit messages for the doc and www trees' => {
     'process' => 'process_cvs_mail',
     'repo'    => '',
     },
  '\*\*OBSOLETE\*\* CVS commit messages for the entire tree' => {
     'process' => 'process_cvs_mail',
     'repo'    => '',
     },
  '\*\*OBSOLETE\*\* CVS commit messages for the src tree' => {
     'process' => 'process_cvs_mail',
     'repo'    => '',
     },
  'CVS commit messages for the projects tree' => {
     'process' => 'process_cvs_mail',
     'repo'    => '',
     },
);

#
# given a list id, grab the properties for it
#
sub ListProperties($)
{
 my $ListId = shift;
 my $hash;

 # strip off the leading header. 
 $ListId =~ s/List-Id:\s+//;

 $hash = $FreshPorts::Branches::MailingLists{$ListId};

 return $hash;
}

#
# convert branches/quarter to just quarter
# e.g. branches/2020Q3 becomes 2020Q3
#

sub stripBranchesToGetBranchName($)
{
  my $branch = shift;

  $branch =~ s/^branches\///;
  
  return $branch;
}

# SVN
# for a given branch name, return the full path.  Including the CHROOT path.
sub GetPathToRepoForBranchSVN($)
{
  my $CommitBranch = shift;

  return "$FreshPorts::Config::RepoDir/PORTS-$CommitBranch";
}

# SVN
# for a given branch name, return the chroot'd full path.
# branches and trunk are now in the same direcvtory
# This is relative to the chroot at FreshPorts::Config::JailBaseDir
#
sub GetPathToRepoForBranchCHROOTSVN($)
{
  my $CommitBranch = shift;
  my $Path;

  # typically '/usr/ports' for git
  $Path = "$FreshPorts::Config::PortsDir";
  
  return $Path
}





#
# for a given branch name, return the repo name. This is a directory.
# it is not fully qualfied.
#
sub GetRepoNameForBranch($;$)
{
  my $Repository   = shift;
  my $CommitBranch = shift;

  # yes, we are not using branch.
  my $RepoName = $FreshPorts::Constants::GitRepos{$Repository};

  if (!defined($RepoName)) {
     FreshPorts::Utilities::ReportError('warning', "Could not find RepoName for Repository='$Repository' & CommitBranch='$CommitBranch'", 1);
     $RepoName = 'freebsd-ports';
  }
  
  return $RepoName
}

#
# for a given branch name, return the chroot'd full path.
# branches and trunk are now in the same direcvtory
# This is relative to the chroot at FreshPorts::Config::JailBaseDir
#
sub GetPathToRepoForBranchCHROOT($;$)
{
  my $Repository   = shift;
  my $CommitBranch = shift;
  my $Path;

  my $RepoName = GetRepoNameForBranch($Repository, $CommitBranch);

  # typically '/usr/ports' for git
  $Path = "$FreshPorts::Config::PortsDir";
  
  return $Path
}

#
# for a given branch name, return the full path.  Including the CHROOT path.
# We assume this is a ports commit, which we can't do once we start processing
# git commits for src and doc.
#
sub GetPathToRepoForBranch($;$)
{
  my $Repository   = shift;
  my $CommitBranch = shift;

  $Path = GetPathToRepoForBranchCHROOT($Repository, $CommitBranch);
  
  return "$FreshPorts::Config::JailBaseDir$Path";
}

# can we process this branch?
# I think this is only used by svn processing at present.  This function is invoked
# only from within process_svn_mail.pm
#
sub CanWeProcessThisBranch($;$)
{
  my $CommitBranch = shift;
  
  my $RepoPath = GetPathToRepoForBranchSVN($CommitBranch);
  
  FreshPorts::Utilities::Report('notice', "Let us verify that RepoPath ('$RepoPath') for Branch '$CommitBranch' actually exists on disk.");

  if (-e $RepoPath && -d $RepoPath)
  {
      return 1;
  }
  else
  {
      return 0;
  }
}

sub GetBranchFromPathName($)
{
  my $pathname = shift();

  # convert /ports/branches/2014Q1/archivers/hs-tar to 2014Q1
  # convert /ports/head/archivers/hs-tar            to head
  # convert /ports/head/accessibility/accerciser    to head

  # the variable names used here assume HEAD  
  #
  my ($emptyLeadingSlash, $subtree, $branch, $category, $port) = split/\//,$pathname, 5;

  # example result based on above
  #        undefined            'ports'    'head'  'archivers'  'hs-tar'

  print "GetBranchFromPathName finds: '$subtree', '$category', '$port'\n";
  if ($subtree ne $FreshPorts::Constants::PORTS) {
    die("Unrecognized structure for pathname('$pathname'): $emptyLeadingSlash, $subtree, $category, $port");
  }

  if ($branch eq $FreshPorts::Constants::HEAD)
  {
    return $branch;
  } else {
    if ($branch eq 'branches')
    {
      return $category;
    } else {
      die("Unable to determine branch for '$pathname'\n");
    }
  }

  die("Faulty code logic.  We should never get here in GetBranchFromPathName\n");
}

sub SetBranchInDB($$) {
  my $dbh    = shift();
  my $branch = shift();

  $sql = 'select freshports_branch_set(' . $dbh->quote($branch) . ')';
  $sth = $dbh->prepare($sql);
  if (!$sth->execute())  {
    FreshPorts::Utilities::Report('warning', "SetBranchInDB: Could not set branch:" .  $dbh->errstr);
  }
  
  $sth->finish();
}

FreshPorts::Utilities::InitSyslog();

1;
