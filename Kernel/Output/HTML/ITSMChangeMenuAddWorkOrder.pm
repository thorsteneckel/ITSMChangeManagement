# --
# Kernel/Output/HTML/ITSMChangeMenuAddWorkOrder.pm - Menu module with check for the permission group
# Copyright (C) 2001-2013 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::ITSMChangeMenuAddWorkOrder;

use strict;
use warnings;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for my $Object (
        qw(ConfigObject EncodeObject LogObject DBObject LayoutObject UserObject GroupObject ChangeObject UserID)
        )
    {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{Change} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need Change!',
        );
        return;
    }

    # get config for the relevant action
    my $FrontendConfig
        = $Self->{ConfigObject}->Get("ITSMChange::Frontend::$Param{Config}->{Action}");

    # get the required privilege, 'ro' or 'rw'
    my $RequiredPriv;
    if ($FrontendConfig) {

        # get the required priv from the frontend configuration
        $RequiredPriv = $FrontendConfig->{Permission};
    }

    my $Access;
    if ( !$RequiredPriv ) {

        # Display the menu-link, when no privilege is required
        $Access = 1;
    }
    else {

        # get the required group for the frontend module
        my $Group = $Self->{ConfigObject}->Get('Frontend::Module')->{ $Param{Config}->{Action} }
            ->{GroupRo}->[0];

        # deny access, when the group is not found
        return $Param{Counter} if !$Group;

        # get the group id
        my $GroupID = $Self->{GroupObject}->GroupLookup( Group => $Group );

        # deny access, when the group is not found
        return $Param{Counter} if !$GroupID;

        # get user groups, where the user has the appropriate privilege
        my %Groups = $Self->{GroupObject}->GroupMemberList(
            UserID => $Self->{UserID},
            Type   => $RequiredPriv,
            Result => 'HASH',
        );

        # grant access if the agent has the appropriate type in the appropriate group
        if ( $Groups{$GroupID} ) {
            $Access = 1;
        }
    }

    return $Param{Counter} if !$Access;

    # output menu block
    $Self->{LayoutObject}->Block( Name => 'Menu' );

    # output separator, when this is not the first menu item
    if ( $Param{Counter} ) {
        $Self->{LayoutObject}->Block( Name => 'MenuItemSplit' );
    }

    # output menu item
    $Self->{LayoutObject}->Block(
        Name => 'MenuItem',
        Data => {
            %Param,
            %{ $Param{Change} },
            %{ $Param{Config} },
        },
    );

    $Param{Counter}++;

    return $Param{Counter};
}

1;
