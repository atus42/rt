# BEGIN LICENSE BLOCK
# 
# Copyright (c) 1996-2003 Jesse Vincent <jesse@bestpractical.com>
# 
# (Except where explictly superceded by other copyright notices)
# 
# This work is made available to you under the terms of Version 2 of
# the GNU General Public License. A copy of that license should have
# been provided with this software, but in any event can be snarfed
# from www.gnu.org.
# 
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# Unless otherwise specified, all modifications, corrections or
# extensions to this work which alter its source code become the
# property of Best Practical Solutions, LLC when submitted for
# inclusion in the work.
# 
# 
# END LICENSE BLOCK

# Autogenerated by DBIx::SearchBuilder factory (by <jesse@bestpractical.com>)
# WARNING: THIS FILE IS AUTOGENERATED. ALL CHANGES TO THIS FILE WILL BE LOST.  
# 
# !! DO NOT EDIT THIS FILE !!
#

use strict;


=head1 NAME

RT::Principal


=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

package RT::Principal;
use RT::Record; 


use vars qw( @ISA );
@ISA= qw( RT::Record );

sub _Init {
  my $self = shift; 

  $self->Table('Principals');
  $self->SUPER::_Init(@_);
}





=head2 Create PARAMHASH

Create takes a hash of values and creates a row in the database:

  varchar(16) 'PrincipalType'.
  int(11) 'ObjectId'.
  smallint(6) 'Disabled'.

=cut




sub Create {
    my $self = shift;
    my %args = ( 
                PrincipalType => '',
                ObjectId => '',
                Disabled => '0',

		  @_);
    $self->SUPER::Create(
                         PrincipalType => $args{'PrincipalType'},
                         ObjectId => $args{'ObjectId'},
                         Disabled => $args{'Disabled'},
);

}



=head2 id

Returns the current value of id. 
(In the database, id is stored as int(11).)


=cut


=head2 PrincipalType

Returns the current value of PrincipalType. 
(In the database, PrincipalType is stored as varchar(16).)



=head2 SetPrincipalType VALUE


Set PrincipalType to VALUE. 
Returns (1, 'Status message') on success and (0, 'Error Message') on failure.
(In the database, PrincipalType will be stored as a varchar(16).)


=cut


=head2 ObjectId

Returns the current value of ObjectId. 
(In the database, ObjectId is stored as int(11).)



=head2 SetObjectId VALUE


Set ObjectId to VALUE. 
Returns (1, 'Status message') on success and (0, 'Error Message') on failure.
(In the database, ObjectId will be stored as a int(11).)


=cut


=head2 Disabled

Returns the current value of Disabled. 
(In the database, Disabled is stored as smallint(6).)



=head2 SetDisabled VALUE


Set Disabled to VALUE. 
Returns (1, 'Status message') on success and (0, 'Error Message') on failure.
(In the database, Disabled will be stored as a smallint(6).)


=cut



sub _CoreAccessible {
    {
     
        id =>
		{read => 1, type => 'int(11)', default => ''},
        PrincipalType => 
		{read => 1, write => 1, type => 'varchar(16)', default => ''},
        ObjectId => 
		{read => 1, write => 1, type => 'int(11)', default => ''},
        Disabled => 
		{read => 1, write => 1, type => 'smallint(6)', default => '0'},

 }
};


        eval "require RT::Principal_Overlay";
        if ($@ && $@ !~ qr{^Can't locate RT/Principal_Overlay.pm}) {
            die $@;
        };

        eval "require RT::Principal_Vendor";
        if ($@ && $@ !~ qr{^Can't locate RT/Principal_Vendor.pm}) {
            die $@;
        };

        eval "require RT::Principal_Local";
        if ($@ && $@ !~ qr{^Can't locate RT/Principal_Local.pm}) {
            die $@;
        };




=head1 SEE ALSO

This class allows "overlay" methods to be placed
into the following files _Overlay is for a System overlay by the original author,
_Vendor is for 3rd-party vendor add-ons, while _Local is for site-local customizations.  

These overlay files can contain new subs or subs to replace existing subs in this module.

If you'll be working with perl 5.6.0 or greater, each of these files should begin with the line 

   no warnings qw(redefine);

so that perl does not kick and scream when you redefine a subroutine or variable in your overlay.

RT::Principal_Overlay, RT::Principal_Vendor, RT::Principal_Local

=cut


1;
