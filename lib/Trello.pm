package Trello;

use 5.008;
use strict;
use warnings;

use Moose;
with 'Role::REST::Client';

use URI::Escape;
use Data::Dumper;

=head1 NAME

Trello - An interface to the Trello application.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Trello is a library to connect to the Trello API in order to manage your boards.

A common way to use it is:

    use Trello;

    my $trello = Trello->new(
	    key   => 'key',
	    token => 'token',
        board => 'board_id');

    # Get card information.
    my $card = $trello->searchCardByShortUrl('https://trello.com/c/Sufdpech');
    ...

=head1 SUBROUTINES/METHODS

=head2 getLists

Obtain the board lists (or columns).

=cut
sub getLists {
	my $self = shift;

	die "Board id undefined\n" unless defined($self->board);

	my $api = uri_escape($self->version);
	my $arguments = $self->authArgs();

	my $response =  $self->get("$api/boards/" . $self->board . "/lists",
							   $arguments);
	if ($response->code == 200) {
		return $response->data;
	}

	return [];
}

=head1 SUBROUTINES/METHODS

=head2 searchLists

Search a list or column by its name.

=cut
sub searchList {
	my $self = shift;
	my $listName = shift;

	die "Need the list name\n" unless defined($listName);

	my $lists = $self->getLists();
	foreach my $list (@$lists) {
		if ($list->{name} eq $listName) {
			return $list;
		}
	}

	return {};
}

=head2 createCard

Create a new card in trello.

=cut
sub createCard {
	my $self = shift;
	my $idList = shift;
	my $cardTitle = shift;
	my $cardDescription = shift;

	die "Board id undefined\n" unless defined($self->board);
	die "The card title is needed to create it\n" unless defined($cardTitle);
	die "The list id is needed to create the card\n" unless defined($idList);

	my $api = uri_escape($self->version);
	my $arguments = $self->authArgs();
	$arguments->{name} = $cardTitle;
	$arguments->{desc} = $cardDescription;
	$arguments->{pos} = 'top';
	$arguments->{idList} = $idList;
	# $argument->{idLabels} = '';

	my $response =  $self->post("$api/cards", $arguments);
	if ($response->code == 200) {
		return $response->data;
	}

	print "Response code: " . $response->code . "\n";
	print Dumper($response->data);

	return {};
}

=head2 getCards

Obtain the board cards.

=cut
sub getCards {
	my $self = shift;

	die "Board id undefined\n" unless defined($self->board);

	my $api = uri_escape($self->version);
	my $arguments = $self->authArgs();

	my $response =  $self->get("$api/boards/" . $self->board . "/cards",
							   $arguments);
	if ($response->code == 200) {
		return $response->data;
	}

	return [];
}

=head2 getCard

Obtain the card information.

=cut
sub getCard {
	my $self = shift;
	my $cardId = shift;

	die "Need the card id information\n" unless defined($cardId);

	my $api = uri_escape($self->version);
	my $arguments = $self->authArgs();

	my $response = $self->get("$api/cards/$cardId", $arguments);
	if ($response->code == 200) {
		return $response->data;
	}

	return [];
}

=head2 getCardCustomFields

Get a card custom fields.

=cut
sub getCardCustomFields {
	my $self = shift;
	my $cardId = shift;

	die "Need the card id information\n" unless defined($cardId);

	my $api = uri_escape($self->version);
	my $arguments = $self->authArgs();

	my $response = $self->get("$api/cards/$cardId/customFields", $arguments);
	if ($response->code == 200) {
		return $response->data;
	}

	return [];
}

=head2 getCardCustomField

Get a card custom field filtered by its name.

=cut
sub getCardCustomField {
	my $self = shift;
	my $cardId = shift;
	my $fieldName = shift;

	die "Need the card id information\n" unless defined($cardId);
	die "Need the field name information\n" unless defined($fieldName);

	my $fields = $self->getCardCustomFields($cardId);
	foreach my $field (@$fields) {
		if ($field->{name} eq $fieldName) {
			return $field;
		}
	}

	return {};
}

=head2 setCardCustomField

Set a card custom field filtered by its id.

=cut
sub setCardCustomField {
	my $self = shift;
	my $cardId = shift;
	my $fieldId = shift;
	my $fieldValue = shift;

	die "Need the card id information\n" unless defined($cardId);
	die "Need the field id information\n" unless defined($fieldId);
	die "Need the field value information\n" unless defined($fieldValue);

	my $api = uri_escape($self->version);
	my $arguments = $self->authArgs();
	my $value = {"text" => $fieldValue };
	$arguments->{value} = $value;

	my $response = $self->put("$api/cards/$cardId/customField/$fieldId/item",
							  $arguments);
	if ($response->code == 200) {
		return 1;
	}

	return 0;
}

=head2 setCardCustomFieldByName

Set a card custom field filtered by its name.

=cut
sub setCardCustomFieldByName {
	my $self = shift;
	my $cardId = shift;
	my $fieldName = shift;
	my $fieldValue = shift;

	die "Need the card id information\n" unless defined($cardId);
	die "Need the field name information\n" unless defined($fieldName);
	die "Need the field value information\n" unless defined($fieldValue);

	my $field = $self->getCardCustomField($cardId, $fieldName);
	die "Field $fieldName not found" unless defined($field->{id});

	return $self->setCardCustomField($cardId, $field->{id}, $fieldValue);
}

=head2 searchCardBy

Obtain the card information based on one field passed by argument.

=cut
sub searchCardBy {
	my $self = shift;
	my $fieldName = shift;
	my $fieldValue = shift;

	die "Need the field name information\n" unless defined($fieldName);
	die "Need the field value information\n" unless defined($fieldValue);

	my $cards = $self->getCards();
	foreach my $card (@$cards) {
		if ($card->{$fieldName} eq $fieldValue) {
			return $card;
		}
	}

	return {};
}

=head2 searchCardByName

Obtain the card information based on its name.

=cut
sub searchCardByName {
	my $self = shift;
	my $cardName = shift;

	die "Need the card name information\n" unless defined($cardName);

	return $self->searchCardBy('name', $cardName);
}

=head2 searchCardByShortUrl

Obtain the card information based on its short url.

=cut
sub searchCardByShortUrl {
	my $self = shift;
	my $cardUrl = shift;

	die "Need the card url information\n" unless defined($cardUrl);

	return $self->searchCardBy('shortUrl', $cardUrl);
}

=head2 searchCardByUrl

Obtain the card information based on its full url.

=cut
sub searchCardByUrl {
	my $self = shift;
	my $cardUrl = shift;

	die "Need the card url information\n" unless defined($cardUrl);

	return $self->searchCardBy('url', $cardUrl);
}

=head2 moveCard

Move the card to a new list.

=cut
sub moveCard {
	my $self = shift;
	my $cardId = shift;
	my $listId = shift;

	die "Need the card id information\n" unless defined($cardId);
	die "Need the list id information\n" unless defined($listId);

	my $api = uri_escape($self->version);
	my $arguments = $self->authArgs();
	$arguments->{idList} = $listId;

	my $response =  $self->put("$api/cards/$cardId", $arguments);
	if ($response->code != 200) {
		return 0;
	}

	return 1;
}

=head2 moveCardByName

Move the card to a new list selected by name.

=cut
sub moveCardByName {
	my $self = shift;
	my $cardName = shift;
	my $listName = shift;

	die "Need the card name information\n" unless defined($cardName);
	die "Need the list name information\n" unless defined($listName);

	my $list = $self->searchList($listName);
	my $card = $self->searchCard($cardName);

	my $api = uri_escape($self->version);
	my $arguments = $self->authArgs();
	$arguments->{idList} = $list->{id};

	my $response = $self->put("$api/cards/" . $card->{id}, $arguments);
	if ($response->code != 200) {
		return 0;
	}

	return 1;
}

=head2 archiveCard

Archive a card by its id.

=cut
sub archiveCard {
	my $self = shift;
	my $cardId = shift;

	die "Need the card id information\n" unless defined($cardId);

	my $api = uri_escape($self->version);
	my $arguments = $self->authArgs();
	$arguments->{closed} = 1;

	my $response = $self->put("$api/cards/" . $cardId, $arguments);
	if ($response->code != 200) {
		return 0;
	}

	return 1;
}

=head2 appendCardDescription

Append information to the card description.

=cut
sub appendCardDescription {
	my $self = shift;
	my $cardId = shift;
	my $description = shift;

	die "Need the card id information\n" unless defined($cardId);
	die "Need the new description\n" unless defined($description);

	my $card = $self->searchCardBy('id', $cardId);

	my $api = uri_escape($self->version);
	my $arguments = $self->authArgs();
	$arguments->{desc} = $card->{desc} . $description;

	my $response = $self->put("$api/cards/" . $card->{id}, $arguments);
	if ($response->code != 200) {
		return 0;
	}

	return 1;
}

=head2 replaceCardDescription

Replace the card description.

=cut
sub replaceCardDescription {
	my $self = shift;
	my $cardId = shift;
	my $description = shift;

	die "Need the card id information\n" unless defined($cardId);
	die "Need the new description\n" unless defined($description);

	my $api = uri_escape($self->version);
	my $arguments = $self->authArgs();
	$arguments->{desc} = $description;

	my $response = $self->put("$api/cards/" . $cardId, $arguments);
	if ($response->code != 200) {
		return 0;
	}

	return 1;
}

=head2 addCardMemberById

Add a member to a card by its id.

=cut
sub addCardMemberById {
	my $self = shift;
	my $cardId = shift;
	my $memberId = shift;

	die "Need the card id information\n" unless defined($cardId);
	die "Need the member id to add\n" unless defined($memberId);

	my $card = $self->searchCardBy('id', $cardId);
	unless (defined $card->{id}) {
		print "Card $cardId not found.\n";
		return 0;
	}

	my @members = ($memberId);
	if (defined($card->{idMembers})) {
		push(@members, @{$card->{idMembers}});
	}

	my $api = uri_escape($self->version);
	my $arguments = $self->authArgs();
	$arguments->{idMembers} = join(',', @members);

	my $response = $self->put("$api/cards/" . $card->{id}, $arguments);
	if ($response->code != 200) {
		return 0;
	}

	return 1;
}

=head2 addCardMemberByName

Add a member to a card by its name.

=cut
sub addCardMemberByName {
	my $self = shift;
	my $cardId = shift;
	my $memberName = shift;

	die "Need the card id information\n" unless defined($cardId);
	die "Need the member to add\n" unless defined($memberName);

	my $member = $self->searchMember($memberName);
	die "Member $memberName not found" unless defined($member->{id});

	return $self->addCardMemberById($cardId, $member->{id});
}

=head2 removeCardMember

Remove a member from a card.

=cut
sub removeCardMember {
	my $self = shift;
	my $cardId = shift;
	my $memberName = shift;

	die "Need the card id information\n" unless defined($cardId);
	die "Need the member name to remove\n" unless defined($memberName);

	my $member = $self->searchMember($memberName);
	die "Member $memberName not found" unless defined($member->{id});

	my $card = $self->searchCardBy('id', $cardId);
	my @members = grep { $_ != $member->{id} } split(/,/, $card->{idMembers});

	my $api = uri_escape($self->version);
	my $arguments = $self->authArgs();
	$arguments->{idMembers} = join(',', @members);

	my $response = $self->put("$api/cards/" . $card->{id}, $arguments);
	if ($response->code != 200) {
		return 0;
	}

	return 1;
}

=head2 getBoard

Get all the information related to a board by id.

=cut
sub getBoard {
	my $self = shift;
	my $boardId = shift;

	die "Need the board id information\n" unless defined($boardId);

	my $api = uri_escape($self->version);
	my $arguments = $self->authArgs();

	my $response = $self->get("$api/boards/$boardId", $arguments);
	if ($response->code != 200) {
		return {};
	}

	return $response->data;
}

=head2 searchBoard

Search for a board based on its name. It uses the trello search, so it works
with partial names. If it finds more than one board it returns the first board
found.

=cut
sub searchBoard {
	my $self = shift;
	my $boardName = shift;

	die "Need the board name information\n" unless defined($boardName);

	my $api = uri_escape($self->version);
	my $arguments = $self->authArgs();
	$arguments->{query} = $boardName;
	$arguments->{modelTypes} = "boards";

	my $response = $self->get("$api/search", $arguments);
	if ($response->code != 200 || @{$response->data->{boards}} == 0) {
		return {};
	}

	if (@{$response->data->{boards}} > 1) {
		print "We have found more than one board, returning the first one\n";
	}

	return $self->getBoard($response->data->{boards}->[0]->{id});
}

=head2 getMember

Get all the information related to a member by id.

=cut
sub getMember {
	my $self = shift;
	my $memberId = shift;

	die "Need the member id information\n" unless defined($memberId);

	my $api = uri_escape($self->version);
	my $arguments = $self->authArgs();

	my $response = $self->get("$api/members/$memberId", $arguments);
	if ($response->code != 200) {
		return {};
	}

	return $response->data;
}

=head2 searchMember

Search for a member based on its name. It uses the trello search, so it works
with partial names. If it finds more than one board it returns the first member
found.

=cut
sub searchMember {
	my $self = shift;
	my $memberName = shift;

	die "Need the member name\n" unless defined($memberName);

	my $api = uri_escape($self->version);
	my $arguments = $self->authArgs();
	$arguments->{query} = $memberName;
	$arguments->{modelTypes} = "members";

	my $response = $self->get("$api/search/members/", $arguments);
	if ($response->code != 200 || @{$response->data} == 0) {
		return {};
	}

	if (@{$response->data} > 1) {
		print "We have found more than one member, returning the first one\n";
	}

	return $self->getMember($response->data->[0]->{id});
}

=head2 authArgs

Prepare and return the authentication list to send on each request.

=cut
sub authArgs {
	my $self = shift;

	my $arguments = {};
	$arguments->{key} = $self->key;
	$arguments->{token} = $self->token;

	return $arguments;
}

=head2 key

This attribute accepts your L<Trello|https://www.trello.com> developer key.
L<Trello|https://www.trello.com> requires that all users of the API have a
unique key. Please refer to the L<Trello|https://www.trello.com> API
documentation to obtain a key.

=cut

has 'key' => (
	is  => 'rw',
	isa => 'Str',
);


=head2 token

This attribute holds the L<Trello|https://www.trello.com> authorization token.
The authorization token tells L<Trello|https://www.trello.com> that this script
can modify your boards and lists.

For example, I use these scripts in C<cron> jobs. So I generate a forever token
once, then code it into the script.

=cut

has 'token' => (
	is  => 'rw',
	isa => 'Str',
);


=head2 board

This attribute holds the L<Trello|https://www.trello.com> board id.

=cut

has 'board' => (
	is  => 'rw',
	isa => 'Str',
);


=head2 server

This attribute holds the URL to the L<Trello|https://www.trello.com> web
server. The class sets this for you. You can read the value from this attribute
if your code wants to know the URL for some reason.

=cut

has '+server' => (
	default  => 'https://api.trello.com/',
);


=head2 version

This attribute tells L<Trello|https://www.trello.com> that we are using version
1 of the API. L<Trello|https://www.trello.com> supports API changes by
including the version number in each request. Currently there is only one
version. This atribute lets the object handle future versions without any code
changes.

You may pass the version to the constructor, if the default value of B<1> does
not meet your needs.

=cut

has 'version' => (
	default => 1,
	is      => 'rw',
	isa     => 'Int',
);

=head1 AUTHOR

Pablo Alvarez de Sotomayor, C<< <pablo.alvarez at lana.xyz> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-trello at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Trello>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Trello


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Trello>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Trello>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Trello>

=item * Search CPAN

L<https://metacpan.org/release/Trello>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Pablo Alvarez de Sotomayor.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Trello
