# BEGIN BPS TAGGED BLOCK {{{
#
# COPYRIGHT:
#
# This software is Copyright (c) 1996-2005 Best Practical Solutions, LLC
#                                          <jesse@bestpractical.com>
#
# (Except where explicitly superseded by other copyright notices)
#
#
# LICENSE:
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
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#
# CONTRIBUTION SUBMISSION POLICY:
#
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of
# the GNU General Public License and is only of importance to you if
# you choose to contribute your changes and enhancements to the
# community by submitting them to Best Practical Solutions, LLC.)
#
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with
# Request Tracker, to Best Practical Solutions, LLC, you confirm that
# you are the copyright holder for those contributions and you grant
# Best Practical Solutions,  LLC a nonexclusive, worldwide, irrevocable,
# royalty-free, perpetual, license to use, copy, create derivative
# works based on those contributions, and sublicense and distribute
# those contributions and any derivatives thereof.
#
# END BPS TAGGED BLOCK }}}
package RT::Interface::Email;

use strict;
use Mail::Address;
use MIME::Entity;
use RT::EmailParser;
use File::Temp;
use UNIVERSAL::require;

BEGIN {
    use Exporter ();
    use vars qw ( @ISA @EXPORT_OK);

    # set the version for version checking
    our $VERSION = 2.0;

    @ISA = qw(Exporter);

    # your exported package globals go here,
    # as well as any optionally exported functions
    @EXPORT_OK = qw(
        &CreateUser
        &GetMessageContent
        &CheckForLoops
        &CheckForSuspiciousSender
        &CheckForAutoGenerated
        &CheckForBounce
        &MailError
        &ParseCcAddressesFromHead
        &ParseSenderAddressFromHead
        &ParseErrorsToAddressFromHead
        &ParseAddressFromHeader
        &Gateway);

}

=head1 NAME

  RT::Interface::Email - helper functions for parsing email sent to RT

=head1 SYNOPSIS

  use lib "!!RT_LIB_PATH!!";
  use lib "!!RT_ETC_PATH!!";

  use RT::Interface::Email  qw(Gateway CreateUser);

=head1 DESCRIPTION


=begin testing

ok(require RT::Interface::Email);

=end testing


=head1 METHODS

=cut

# {{{ sub CheckForLoops

sub CheckForLoops {
    my $head = shift;

    #If this instance of RT sent it our, we don't want to take it in
    my $RTLoop = $head->get("X-RT-Loop-Prevention") || "";
    chomp($RTLoop);    #remove that newline
    if ( $RTLoop eq "$RT::rtname" ) {
        return (1);
    }

    # TODO: We might not trap the case where RT instance A sends a mail
    # to RT instance B which sends a mail to ...
    return (undef);
}

# }}}

# {{{ sub CheckForSuspiciousSender

sub CheckForSuspiciousSender {
    my $head = shift;

    #if it's from a postmaster or mailer daemon, it's likely a bounce.

    #TODO: better algorithms needed here - there is no standards for
    #bounces, so it's very difficult to separate them from anything
    #else.  At the other hand, the Return-To address is only ment to be
    #used as an error channel, we might want to put up a separate
    #Return-To address which is treated differently.

    #TODO: search through the whole email and find the right Ticket ID.

    my ( $From, $junk ) = ParseSenderAddressFromHead($head);

    if (   ( $From =~ /^mailer-daemon\@/i )
        or ( $From =~ /^postmaster\@/i ) )
    {
        return (1);

    }

    return (undef);

}

# }}}

# {{{ sub CheckForAutoGenerated
sub CheckForAutoGenerated {
    my $head = shift;

    my $Precedence = $head->get("Precedence") || "";
    if ( $Precedence =~ /^(bulk|junk)/i ) {
        return (1);
    }

    # First Class mailer uses this as a clue.
    my $FCJunk = $head->get("X-FC-Machinegenerated") || "";
    if ( $FCJunk =~ /^true/i ) {
        return (1);
    }

    return (0);
}

# }}}

# {{{ sub CheckForBounce
sub CheckForBounce {
    my $head = shift;

    my $ReturnPath = $head->get("Return-path") || "";
    return ( $ReturnPath =~ /<>/ );
}

# }}}

# {{{ IsRTAddress

=head2 IsRTAddress ADDRESS

Takes a single parameter, an email address. 
Returns true if that address matches the $RTAddressRegexp.  
Returns false, otherwise.

=cut

sub IsRTAddress {
    my $address = shift || '';

    # Example: the following rule would tell RT not to Cc
    #   "tickets@noc.example.com"
    if ( defined($RT::RTAddressRegexp)
        && $address =~ /$RT::RTAddressRegexp/i )
    {
        return (1);
    } else {
        return (undef);
    }
}

# }}}

# {{{ CullRTAddresses

=head2 CullRTAddresses ARRAY

Takes a single argument, an array of email addresses.
Returns the same array with any IsRTAddress()es weeded out.

=cut

sub CullRTAddresses {
    return ( grep { IsRTAddress($_) } @_ );
}

# }}}

# {{{ sub MailError
sub MailError {
    my %args = (
        To          => $RT::OwnerEmail,
        Bcc         => undef,
        From        => $RT::CorrespondAddress,
        Subject     => 'There has been an error',
        Explanation => 'Unexplained error',
        MIMEObj     => undef,
        Attach      => undef,
        LogLevel    => 'crit',
        @_
    );

    $RT::Logger->log(
        level   => $args{'LogLevel'},
        message => $args{'Explanation'}
    );
    my $entity = MIME::Entity->build(
        Type                   => "multipart/mixed",
        From                   => $args{'From'},
        Bcc                    => $args{'Bcc'},
        To                     => $args{'To'},
        Subject                => $args{'Subject'},
        Precedence             => 'bulk',
        'X-RT-Loop-Prevention' => $RT::rtname,
    );

    $entity->attach( Data => $args{'Explanation'} . "\n" );

    my $mimeobj = $args{'MIMEObj'};
    if ($mimeobj) {
        $mimeobj->sync_headers();
        $entity->add_part($mimeobj);
    }

    if ( $args{'Attach'} ) {
        $entity->attach( Data => $args{'Attach'}, Type => 'message/rfc822' );

    }

    if ( $RT::MailCommand eq 'sendmailpipe' ) {
        open( MAIL,
            "|$RT::SendmailPath $RT::SendmailBounceArguments $RT::SendmailArguments"
            )
            || return (0);
        print MAIL $entity->as_string;
        close(MAIL);
    } else {
        $entity->send( $RT::MailCommand, $RT::MailParams );
    }
}

# }}}

# {{{ Create User

sub CreateUser {
    my ( $Username, $Address, $Name, $ErrorsTo, $entity ) = @_;
    my $NewUser = RT::User->new($RT::SystemUser);

    my ( $Val, $Message ) = $NewUser->Create(
        Name => ( $Username || $Address ),
        EmailAddress => $Address,
        RealName     => $Name,
        Password     => undef,
        Privileged   => 0,
        Comments     => 'Autocreated on ticket submission'
    );

    unless ($Val) {

        # Deal with the race condition of two account creations at once
        #
        if ($Username) {
            $NewUser->LoadByName($Username);
        }

        unless ( $NewUser->Id ) {
            $NewUser->LoadByEmail($Address);
        }

        unless ( $NewUser->Id ) {
            MailError(
                To          => $ErrorsTo,
                Subject     => "User could not be created",
                Explanation =>
                    "User creation failed in mailgateway: $Message",
                MIMEObj  => $entity,
                LogLevel => 'crit'
            );
        }
    }

    #Load the new user object
    my $CurrentUser = RT::CurrentUser->new();
    $CurrentUser->LoadByEmail($Address);

    unless ( $CurrentUser->id ) {
        $RT::Logger->warning(
            "Couldn't load user '$Address'." . "giving up" );
        MailError(
            To          => $ErrorsTo,
            Subject     => "User could not be loaded",
            Explanation =>
                "User  '$Address' could not be loaded in the mail gateway",
            MIMEObj  => $entity,
            LogLevel => 'crit'
        );
    }

    return $CurrentUser;
}

# }}}

# {{{ ParseCcAddressesFromHead

=head2 ParseCcAddressesFromHead HASHREF

Takes a hashref object containing QueueObj, Head and CurrentUser objects.
Returns a list of all email addresses in the To and Cc 
headers b<except> the current Queue\'s email addresses, the CurrentUser\'s 
email address  and anything that the configuration sub RT::IsRTAddress matches.

=cut

sub ParseCcAddressesFromHead {
    my %args = (
        Head        => undef,
        QueueObj    => undef,
        CurrentUser => undef,
        @_
    );

    my (@Addresses);

    my @ToObjs = Mail::Address->parse( $args{'Head'}->get('To') );
    my @CcObjs = Mail::Address->parse( $args{'Head'}->get('Cc') );

    foreach my $AddrObj ( @ToObjs, @CcObjs ) {
        my $Address = $AddrObj->address;
        $Address = $args{'CurrentUser'}
            ->UserObj->CanonicalizeEmailAddress($Address);
        next if ( $args{'CurrentUser'}->EmailAddress   =~ /^\Q$Address\E$/i );
        next if ( $args{'QueueObj'}->CorrespondAddress =~ /^\Q$Address\E$/i );
        next if ( $args{'QueueObj'}->CommentAddress    =~ /^\Q$Address\E$/i );
        next if ( RT::EmailParser->IsRTAddress($Address) );

        push( @Addresses, $Address );
    }
    return (@Addresses);
}

# }}}

# {{{ ParseSenderAdddressFromHead

=head2 ParseSenderAddressFromHead

Takes a MIME::Header object. Returns a tuple: (user@host, friendly name) 
of the From (evaluated in order of Reply-To:, From:, Sender)

=cut

sub ParseSenderAddressFromHead {
    my $head = shift;

    #Figure out who's sending this message.
    my $From = $head->get('Reply-To')
        || $head->get('From')
        || $head->get('Sender');
    return ( ParseAddressFromHeader($From) );
}

# }}}

# {{{ ParseErrorsToAdddressFromHead

=head2 ParseErrorsToAddressFromHead

Takes a MIME::Header object. Return a single value : user@host
of the From (evaluated in order of Return-path:,Errors-To:,Reply-To:,
From:, Sender)

=cut

sub ParseErrorsToAddressFromHead {
    my $head = shift;

    #Figure out who's sending this message.

    foreach my $header ( 'Errors-To', 'Reply-To', 'From', 'Sender' ) {

        # If there's a header of that name
        my $headerobj = $head->get($header);
        if ($headerobj) {
            my ( $addr, $name ) = ParseAddressFromHeader($headerobj);

            # If it's got actual useful content...
            return ($addr) if ($addr);
        }
    }
}

# }}}

# {{{ ParseAddressFromHeader

=head2 ParseAddressFromHeader ADDRESS

Takes an address from $head->get('Line') and returns a tuple: user@host, friendly name

=cut

sub ParseAddressFromHeader {
    my $Addr = shift;

    my @Addresses = Mail::Address->parse($Addr);

    my $AddrObj = $Addresses[0];

    unless ( ref($AddrObj) ) {
        return ( undef, undef );
    }

    my $Name = ( $AddrObj->phrase || $AddrObj->comment || $AddrObj->address );

    #Lets take the from and load a user object.
    my $Address = $AddrObj->address;

    return ( $Address, $Name );
}

# }}}

# {{{ sub ParseTicketId

sub ParseTicketId {
    my $Subject = shift;
    my $id;

    my $test_name = $RT::EmailSubjectTagRegex || qr/\Q$RT::rtname\E/i;

    if ( $Subject =~ s/\[$test_name\s+\#(\d+)\s*\]//i ) {
        my $id = $1;
        $RT::Logger->debug("Found a ticket ID. It's $id");
        return ($id);
    } else {
        return (undef);
    }
}

# }}}

=head2 Gateway ARGSREF


Takes parameters:

    action
    queue
    message


This performs all the "guts" of the mail rt-mailgate program, and is
designed to be called from the web interface with a message, user
object, and so on.

Can also take an optional 'ticket' parameter; this ticket id overrides
any ticket id found in the subject.

Returns:

    An array of:
    
    (status code, message, optional ticket object)

    status code is a numeric value.

      for temporary failures, the status code should be -75

      for permanent failures which are handled by RT, the status code 
      should be 0
    
      for succces, the status code should be 1



=cut

sub Gateway {
    my $argsref = shift;
    my %args    = (
        action  => 'correspond',
        queue   => '1',
        ticket  => undef,
        message => undef,
        %$argsref
    );

    my $SystemTicket;
    my $Right;

    # Validate the action
    my ( $status, @actions ) = IsCorrectAction( $args{'action'} );
    unless ($status) {
        return (
            -75,
            "Invalid 'action' parameter "
                . $actions[0]
                . " for queue "
                . $args{'queue'},
            undef
        );
    }

    my $parser = RT::EmailParser->new();
    $parser->SmartParseMIMEEntityFromScalar( Message => $args{'message'} );
    my $Message = $parser->Entity();

    unless ($Message) {
        MailError(
            To          => $RT::OwnerEmail,
            Subject     => "RT Bounce: Unparseable message",
            Explanation => "RT couldn't process the message below",
            Attach      => $args{'message'}
        );

        return ( 0,
            "Failed to parse this message. Something is likely badly wrong with the message"
        );
    }

    my $head = $Message->head;

    my $ErrorsTo = ParseErrorsToAddressFromHead($head);

    my $MessageId = $head->get('Message-ID')
        || "<no-message-id-" . time . rand(2000) . "\@.$RT::Organization>";

    #Pull apart the subject line
    my $Subject = $head->get('Subject') || '';
    chomp $Subject;

    $args{'ticket'} ||= ParseTicketId($Subject);

    $SystemTicket = RT::Ticket->new($RT::SystemUser);
    $SystemTicket->Load( $args{'ticket'} ) if ( $args{'ticket'} ) ;
    if ( $SystemTicket->id ) {
        $Right = 'ReplyToTicket';
    } else {
        $Right = 'CreateTicket';
    }

    #Set up a queue object
    my $SystemQueueObj = RT::Queue->new($RT::SystemUser);
    $SystemQueueObj->Load( $args{'queue'} );

    # We can safely have no queue of we have a known-good ticket
    unless ( $SystemTicket->id || $SystemQueueObj->id ) {
        return ( -75, "RT couldn't find the queue: " . $args{'queue'}, undef );
    }

   # Authentication Level ($AuthStat)
   # -1 - Get out.  this user has been explicitly declined
   # 0 - User may not do anything (Not used at the moment)
   # 1 - Normal user
   # 2 - User is allowed to specify status updates etc. a la enhanced-mailgate
    my ( $CurrentUser, $AuthStat, $error );

    # Initalize AuthStat so comparisons work correctly
    $AuthStat = -9999999;

    push @RT::MailPlugins, "Auth::MailFrom" unless @RT::MailPlugins;

    # if plugin returns AuthStat -2 we skip action
    # NOTE: this is experimental API and it would be changed
    my %skip_action = ();

    # Since this needs loading, no matter what
    foreach (@RT::MailPlugins) {
        my ($Code, $Class, $NewAuthStat);
        if ( ref($_) eq "CODE" ) {
            $Code = $_;
        } else {
            $Class = "RT::Interface::Email::" . $_
                unless $_ =~ /^RT::Interface::Email::/;
            $Class->require or
                do { $RT::Logger->error("Couldn't load $Class: $@"); next };
        }
            no strict 'refs';
            if ( !defined( $Code = *{ $Class . "::GetCurrentUser" }{CODE} ) ) {
                $RT::Logger->crit( "No GetCurrentUser code found in $Class module");
                next;
            }
        

        foreach my $action (@actions) {
            ( $CurrentUser, $NewAuthStat ) = $Code->(
                Message       => $Message,
                RawMessageRef => \$args{'message'},
                CurrentUser   => $CurrentUser,
                AuthLevel     => $AuthStat,
                Action        => $action,
                Ticket        => $SystemTicket,
                Queue         => $SystemQueueObj
            );

# You get the highest level of authentication you were assigned, unless you get the magic -1
# If a module returns a "-1" then we discard the ticket, so.
            $AuthStat = $NewAuthStat
                if ( $NewAuthStat > $AuthStat or $NewAuthStat == -1 or $NewAuthStat == -2 );

            last if $AuthStat == -1;
            $skip_action{$action}++ if $AuthStat == -2;
        }

        last if $AuthStat == -1;
    }
    # {{{ If authentication fails and no new user was created, get out.
    if ( !$CurrentUser || !$CurrentUser->id || $AuthStat == -1 ) {

        # If the plugins refused to create one, they lose.
        unless ( $AuthStat == -1 ) {
            _NoAuthorizedUserFound(
                Right     => $Right,
                Message   => $Message,
                Requestor => $ErrorsTo,
                Queue     => $args{'queue'}
            );

        }
        return ( 0, "Could not load a valid user", undef );
    }

    # If we got a user, but they don't have the right to say things
    if ( $AuthStat == 0 ) {
        MailError(
            To          => $ErrorsTo,
            Subject     => "Permission Denied",
            Explanation =>
                "You do not have permission to communicate with RT",
            MIMEObj => $Message
        );
        return (
            0,
            "$ErrorsTo tried to submit a message to "
                . $args{'Queue'}
                . " without permission.",
            undef
        );
    }

    # {{{ Lets check for mail loops of various sorts.
    my ($continue, $result);
     ( $continue, $ErrorsTo, $result ) = _HandleMachineGeneratedMail(
        Message  => $Message,
        ErrorsTo => $ErrorsTo,
        Subject  => $Subject,
        MessageId => $MessageId
    );

    unless ($continue) {
        return ( 0, $result, undef );
    }
    
    # strip actions we should skip
    @actions = grep !$skip_action{$_}, @actions;

    # if plugin's updated SystemTicket then update arguments
    $args{'ticket'} = $SystemTicket->Id if $SystemTicket && $SystemTicket->Id;

    my $Ticket = RT::Ticket->new($CurrentUser);

    if (( !$SystemTicket || !$SystemTicket->Id )
        && grep /^(comment|correspond)$/, @actions )
    {

        my @Cc;
        my @Requestors = ( $CurrentUser->id );

        if ($RT::ParseNewMessageForTicketCcs) {
            @Cc = ParseCcAddressesFromHead(
                Head        => $head,
                CurrentUser => $CurrentUser,
                QueueObj    => $SystemQueueObj
            );
        }

        my ( $id, $Transaction, $ErrStr ) = $Ticket->Create(
            Queue     => $SystemQueueObj->Id,
            Subject   => $Subject,
            Requestor => \@Requestors,
            Cc        => \@Cc,
            MIMEObj   => $Message
        );
        if ( $id == 0 ) {
            MailError(
                To          => $ErrorsTo,
                Subject     => "Ticket creation failed",
                Explanation => $ErrStr,
                MIMEObj     => $Message
            );
            return ( 0, "Ticket creation failed: $ErrStr", $Ticket );
        }

# strip comments&corresponds from the actions we don't need to record them if we've created the ticket just now
        @actions = grep !/^(comment|correspond)$/, @actions;
        $args{'ticket'} = $id;

    } else {

        $Ticket->Load( $args{'ticket'} );
        unless ( $Ticket->Id ) {
            my $error = "Could not find a ticket with id " . $args{'ticket'};
            MailError(
                To          => $ErrorsTo,
                Subject     => "Message not recorded",
                Explanation => $error,
                MIMEObj     => $Message
            );

            return ( 0, $error );
        }
    }

    # }}}
    foreach my $action (@actions) {

        #   If the action is comment, add a comment.
        if ( $action =~ /^(?:comment|correspond)$/i ) {
            my ( $status, $msg );
            if ( $action =~ /^correspond$/i ) {
                ( $status, $msg )
                    = $Ticket->Correspond( MIMEObj => $Message );
            } else {
                ( $status, $msg ) = $Ticket->Comment( MIMEObj => $Message );
            }
            unless ($status) {

                #Warn the sender that we couldn't actually submit the comment.
                MailError(
                    To          => $ErrorsTo,
                    Subject     => "Message not recorded",
                    Explanation => $msg,
                    MIMEObj     => $Message
                );
                return ( 0, "Message not recorded", $Ticket );
            }
        } elsif ($RT::UnsafeEmailCommands) {
            return _RunUnsafeAction(
                Action      => $action,
                ErrorsTo    => $ErrorsTo,
                Message     => $Message,
                Ticket      => $Ticket,
                CurrentUser => $CurrentUser
            );
        }
    }
    return ( 1, "Success", $Ticket );
}

sub _RunUnsafeAction {
    my %args = (
        Action      => undef,
        ErrorsTo    => undef,
        Message     => undef,
        Ticket      => undef,
        CurrentUser => undef,
        @_
    );

    if ( $args{'Action'} =~ /^take$/i ) {
        my ( $status, $msg ) = $args{'Ticket'}->SetOwner( $args{'CurrentUser'}->id );
        unless ($status) {
            MailError(
                To          => $args{'ErrorsTo'},
                Subject     => "Ticket not taken",
                Explanation => $msg,
                MIMEObj     => $args{'Message'}
            );
            return ( 0, "Ticket not taken", $args{'Ticket'} );
        }
    } elsif ( $args{'Action'} =~ /^resolve$/i ) {
        my ( $status, $msg ) = $args{'Ticket'}->SetStatus('resolved');
        unless ($status) {

            #Warn the sender that we couldn't actually submit the comment.
            MailError(
                To          => $args{'ErrorsTo'},
                Subject     => "Ticket not resolved",
                Explanation => $msg,
                MIMEObj     => $args{'Message'}
            );
            return ( 0, "Ticket not resolved", $args{'Ticket'} );
        }
    }
    return ( 0, 'Unknown action' );
}

=head2 _NoAuthorizedUserFound

Emails the RT Owner and the requestor when the auth plugins return "No auth user found"

=cut

sub _NoAuthorizedUserFound {
    my %args = (
        Right     => undef,
        Message   => undef,
        Requestor => undef,
        Queue     => undef,
        @_
    );

    # Notify the RT Admin of the failure.
    MailError(
        To          => $RT::OwnerEmail,
        Subject     => "Could not load a valid user",
        Explanation => <<EOT,
RT could not load a valid user, and RT's configuration does not allow
for the creation of a new user for this email (@{[$args{Requestor}]}).

You might need to grant 'Everyone' the right '@{[$args{Right}]}' for the
queue @{[$args{'Queue'}]}.

EOT
        MIMEObj  => $args{'Message'},
        LogLevel => 'error'
    );

    # Also notify the requestor that his request has been dropped.
    MailError(
        To          => $args{'Requestor'},
        Subject     => "Could not load a valid user",
        Explanation => <<EOT,
RT could not load a valid user, and RT's configuration does not allow
for the creation of a new user for your email.

EOT
        MIMEObj  => $args{'Message'},
        LogLevel => 'error'
    );
}

=head2 _HandleMachineGeneratedMail

Takes named params:
    Message
    ErrorsTo
    Subject

Checks the message to see if it's a bounce, if it looks like a loop, if it's autogenerated, etc.
Returns a triple of ("Should we continue (boolean)", "New value for $ErrorsTo", "Status message");

=cut

sub _HandleMachineGeneratedMail {
    my %args = ( Message => undef, ErrorsTo => undef, Subject => undef, MessageId => undef, @_ );
    my $head = $args{'Message'}->head;
    my $ErrorsTo = $args{'ErrorsTo'};

    my $IsBounce = CheckForBounce($head);

    my $IsAutoGenerated = CheckForAutoGenerated($head);

    my $IsSuspiciousSender = CheckForSuspiciousSender($head);

    my $IsALoop = CheckForLoops($head);

    my $SquelchReplies = 0;

    #If the message is autogenerated, we need to know, so we can not
    # send mail to the sender
    if ( $IsBounce || $IsSuspiciousSender || $IsAutoGenerated || $IsALoop ) {
        $SquelchReplies = 1;
        $ErrorsTo       = $RT::OwnerEmail;
    }

    # Warn someone if it's a loop, before we drop it on the ground
    if ($IsALoop) {
        $RT::Logger->crit("RT Recieved mail (".$args{MessageId}.") from itself.");

        #Should we mail it to RTOwner?
        if ($RT::LoopsToRTOwner) {
            MailError(
                To          => $RT::OwnerEmail,
                Subject     => "RT Bounce: ".$args{'Subject'},
                Explanation => "RT thinks this message may be a bounce",
                MIMEObj     => $args{Message}
            );
        }

        #Do we actually want to store it?
        return ( 0, $ErrorsTo, "Message Bounced" ) unless ($RT::StoreLoops);
    }

    # Squelch replies if necessary
    # Don't let the user stuff the RT-Squelch-Replies-To header.
    if ( $head->get('RT-Squelch-Replies-To') ) {
        $head->add(
            'RT-Relocated-Squelch-Replies-To',
            $head->get('RT-Squelch-Replies-To')
        );
        $head->delete('RT-Squelch-Replies-To');
    }

    if ($SquelchReplies) {

        # Squelch replies to the sender, and also leave a clue to
        # allow us to squelch ALL outbound messages. This way we
        # can punt the logic of "what to do when we get a bounce"
        # to the scrip. We might want to notify nobody. Or just
        # the RT Owner. Or maybe all Privileged watchers.
        my ( $Sender, $junk ) = ParseSenderAddressFromHead($head);
        $head->add( 'RT-Squelch-Replies-To',    $Sender );
        $head->add( 'RT-DetectedAutoGenerated', 'true' );
    }
    return ( 1, $ErrorsTo, "Handled machine detection" );
}

=head2 IsCorrectAction

Returns a list of valid actions we've found for this message

=cut

sub IsCorrectAction {
    my $action = shift;
    my @actions = split /-/, $action;
    foreach (@actions) {
        return ( 0, $_ ) unless /^(?:comment|correspond|take|resolve)$/;
    }
    return ( 1, @actions );
}

eval "require RT::Interface::Email_Vendor";
die $@ if ( $@ && $@ !~ qr{^Can't locate RT/Interface/Email_Vendor.pm} );
eval "require RT::Interface::Email_Local";
die $@ if ( $@ && $@ !~ qr{^Can't locate RT/Interface/Email_Local.pm} );

1;
