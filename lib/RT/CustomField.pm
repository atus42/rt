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

RT::CustomField


=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

package RT::CustomField;
use RT::Record; 


use vars qw( @ISA );
@ISA= qw( RT::Record );

sub _Init {
  my $self = shift; 

  $self->Table('CustomFields');
  $self->SUPER::_Init(@_);
}





=head2 Create PARAMHASH

Create takes a hash of values and creates a row in the database:

  varchar(200) 'Name'.
  varchar(200) 'Type'.
  int(11) 'MaxValues'.
  varchar(255) 'Pattern'.
  smallint(6) 'Repeated'.
  varchar(255) 'Description'.
  int(11) 'SortOrder'.
  varchar(255) 'LookupType'.
  smallint(6) 'Disabled'.

=cut




sub Create {
    my $self = shift;
    my %args = ( 
                Name => '',
                Type => '',
                MaxValues => '',
                Pattern => '',
                Repeated => '0',
                Description => '',
                SortOrder => '0',
                LookupType => '',
                Disabled => '0',

		  @_);
    $self->SUPER::Create(
                         Name => $args{'Name'},
                         Type => $args{'Type'},
                         MaxValues => $args{'MaxValues'},
                         Pattern => $args{'Pattern'},
                         Repeated => $args{'Repeated'},
                         Description => $args{'Description'},
                         SortOrder => $args{'SortOrder'},
                         LookupType => $args{'LookupType'},
                         Disabled => $args{'Disabled'},
);

}



=head2 id

Returns the current value of id. 
(In the database, id is stored as int(11).)


=cut


=head2 Name

Returns the current value of Name. 
(In the database, Name is stored as varchar(200).)



=head2 SetName VALUE


Set Name to VALUE. 
Returns (1, 'Status message') on success and (0, 'Error Message') on failure.
(In the database, Name will be stored as a varchar(200).)


=cut


=head2 Type

Returns the current value of Type. 
(In the database, Type is stored as varchar(200).)



=head2 SetType VALUE


Set Type to VALUE. 
Returns (1, 'Status message') on success and (0, 'Error Message') on failure.
(In the database, Type will be stored as a varchar(200).)


=cut


=head2 MaxValues

Returns the current value of MaxValues. 
(In the database, MaxValues is stored as int(11).)



=head2 SetMaxValues VALUE


Set MaxValues to VALUE. 
Returns (1, 'Status message') on success and (0, 'Error Message') on failure.
(In the database, MaxValues will be stored as a int(11).)


=cut


=head2 Pattern

Returns the current value of Pattern. 
(In the database, Pattern is stored as varchar(255).)



=head2 SetPattern VALUE


Set Pattern to VALUE. 
Returns (1, 'Status message') on success and (0, 'Error Message') on failure.
(In the database, Pattern will be stored as a varchar(255).)


=cut


=head2 Repeated

Returns the current value of Repeated. 
(In the database, Repeated is stored as smallint(6).)



=head2 SetRepeated VALUE


Set Repeated to VALUE. 
Returns (1, 'Status message') on success and (0, 'Error Message') on failure.
(In the database, Repeated will be stored as a smallint(6).)


=cut


=head2 Description

Returns the current value of Description. 
(In the database, Description is stored as varchar(255).)



=head2 SetDescription VALUE


Set Description to VALUE. 
Returns (1, 'Status message') on success and (0, 'Error Message') on failure.
(In the database, Description will be stored as a varchar(255).)


=cut


=head2 SortOrder

Returns the current value of SortOrder. 
(In the database, SortOrder is stored as int(11).)



=head2 SetSortOrder VALUE


Set SortOrder to VALUE. 
Returns (1, 'Status message') on success and (0, 'Error Message') on failure.
(In the database, SortOrder will be stored as a int(11).)


=cut


=head2 LookupType

Returns the current value of LookupType. 
(In the database, LookupType is stored as varchar(255).)



=head2 SetLookupType VALUE


Set LookupType to VALUE. 
Returns (1, 'Status message') on success and (0, 'Error Message') on failure.
(In the database, LookupType will be stored as a varchar(255).)


=cut


=head2 Creator

Returns the current value of Creator. 
(In the database, Creator is stored as int(11).)


=cut


=head2 Created

Returns the current value of Created. 
(In the database, Created is stored as datetime.)


=cut


=head2 LastUpdatedBy

Returns the current value of LastUpdatedBy. 
(In the database, LastUpdatedBy is stored as int(11).)


=cut


=head2 LastUpdated

Returns the current value of LastUpdated. 
(In the database, LastUpdated is stored as datetime.)


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
        Name => 
		{read => 1, write => 1, type => 'varchar(200)', default => ''},
        Type => 
		{read => 1, write => 1, type => 'varchar(200)', default => ''},
        MaxValues => 
		{read => 1, write => 1, type => 'int(11)', default => ''},
        Pattern => 
		{read => 1, write => 1, type => 'varchar(255)', default => ''},
        Repeated => 
		{read => 1, write => 1, type => 'smallint(6)', default => '0'},
        Description => 
		{read => 1, write => 1, type => 'varchar(255)', default => ''},
        SortOrder => 
		{read => 1, write => 1, type => 'int(11)', default => '0'},
        LookupType => 
		{read => 1, write => 1, type => 'varchar(255)', default => ''},
        Creator => 
		{read => 1, auto => 1, type => 'int(11)', default => '0'},
        Created => 
		{read => 1, auto => 1, type => 'datetime', default => ''},
        LastUpdatedBy => 
		{read => 1, auto => 1, type => 'int(11)', default => '0'},
        LastUpdated => 
		{read => 1, auto => 1, type => 'datetime', default => ''},
        Disabled => 
		{read => 1, write => 1, type => 'smallint(6)', default => '0'},

 }
};


        eval "require RT::CustomField_Overlay";
        if ($@ && $@ !~ qr{^Can't locate RT/CustomField_Overlay.pm}) {
            die $@;
        };

        eval "require RT::CustomField_Vendor";
        if ($@ && $@ !~ qr{^Can't locate RT/CustomField_Vendor.pm}) {
            die $@;
        };

        eval "require RT::CustomField_Local";
        if ($@ && $@ !~ qr{^Can't locate RT/CustomField_Local.pm}) {
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

RT::CustomField_Overlay, RT::CustomField_Vendor, RT::CustomField_Local

=cut


1;
