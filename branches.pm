#!/usr/bin/perl
#
# Copyright (c) 2014 DVL Software
#

package FreshPorts::Branches;

require config;

# these are the branches we can process... I don't see us using this yet.  See CanWeProcesThisBranch()
%FreshPorts::Branches::Branches = (
  'head',
  'RELENG_9_1_0'
);

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
  'SVN commit messages for the ports tree for head' => {
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

# for a given branch name, return the full path.  Including the CHROOT path.
sub GetPathToRepoForBranch($)
{
  my $CommitBranch = shift;
  
  return "$FreshPorts::Config::JailBaseDir/$FreshPorts::Config::SVNBaseDir/PORTS-$CommitBranch";
}

# for a given branch name, return the chroot'd full path.
sub GetPathToRepoForBranchCHROOT($)
{
  my $CommitBranch = shift;
  
  return "$FreshPorts::Config::SVNBaseDir/PORTS-$CommitBranch";
}

# can we process this branch?
sub CanWeProcessThisBranch($)
{
  my $CommitBranch = shift;

  if (-e GetPathToRepoForBranch($CommitBranch) &&
      -d GetPathToRepoForBranch($CommitBranch))
  {
      return 1;
  }
  else
  {
      return 0;
  }
}

1;
