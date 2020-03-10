package Trello;

use 5.008;
use strict;
use warnings;

use Moose;
with 'Role::REST::Client';

use JSON;
use URI::Escape;

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
	    token => 'token';

    my $lists = $trello->get( "boards/$id/lists" );
    $trello->post( "cards", {name => 'New card', idList => $id} );
    ...

=head1 SUBROUTINES/METHODS

=head2 getLists

Obtain the board lists (or columns).

=cut
sub getLists {
	my $self = shift;
	my $boardId = shift;

	die "Need the board id information\n" unless defined($boardId);

	my $api = uri_escape($self->version);
	my $arguments = $self->authArgs();

	my $response =  $self->get("$api/boards/$boardId/lists", $arguments);
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
	my $boardId = shift;
	my $listName = shift;

	die "Need the board id\n" unless defined($boardId);
	die "Need the list name\n" unless defined($listName);

	my $lists = $self->getLists($boardId);
	foreach my $list (@$lists) {
		if ($list->{name} eq $listName) {
			return $list;
		}
	}

	return {};
}

=head2 getCards

Obtain the board cards.

=cut
sub getCards {
	my $self = shift;
	my $boardId = shift;

	die "Need the board id information\n" unless defined($boardId);

	my $arguments = $self->authArgs();
	my $api = uri_escape($self->version);

	my $response =  $self->get("$api/boards/$boardId/cards", $arguments);
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

	my $response =  $self->get("$api/cards/$cardId", $arguments);
	if ($response->code == 200) {
		return $response->data;
	}

	return [];
}

=head2 searchCardBy

Obtain the card information based on one field passed by argument.

=cut
sub searchCardBy {
	my $self = shift;
	my $boardId = shift;
	my $fieldName = shift;
	my $fieldValue = shift;

	die "Need the board id information\n" unless defined($boardId);
	die "Need the field name information\n" unless defined($fieldName);
	die "Need the field value information\n" unless defined($fieldValue);

	my $cards = $self->getCards($boardId);
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
	my $boardId = shift;
	my $cardName = shift;

	die "Need the board id information\n" unless defined($boardId);
	die "Need the card name information\n" unless defined($cardName);

	return $self->searchCardBy($boardId, 'name', $cardName);
}

=head2 searchCardByShortUrl

Obtain the card information based on its short url.

=cut
sub searchCardByShortUrl {
	my $self = shift;
	my $boardId = shift;
	my $cardUrl = shift;

	die "Need the board id information\n" unless defined($boardId);
	die "Need the card url information\n" unless defined($cardUrl);

	return $self->searchCardBy($boardId, 'shortUrl', $cardUrl);
}

=head2 searchCardByUrl

Obtain the card information based on its full url.

=cut
sub searchCardByUrl {
	my $self = shift;
	my $boardId = shift;
	my $cardUrl = shift;

	die "Need the board id information\n" unless defined($boardId);
	die "Need the card url information\n" unless defined($cardUrl);

	return $self->searchCardBy($boardId, 'url', $cardUrl);
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

=head2 moveCard

Move the card to a new list selected by name.

=cut
sub moveCardByName {
	my $self = shift;
	my $boardId = shift;
	my $cardName = shift;
	my $listName = shift;

	die "Need the board id information\n" unless defined($boardId);
	die "Need the card name information\n" unless defined($cardName);
	die "Need the list name information\n" unless defined($listName);

	my $list = $self->searchList($boardId, $listName);
	my $card = $self->searchCard($boardId, $cardName);

	my $api = uri_escape($self->version);
	my $arguments = $self->authArgs();
	$arguments->{idList} = $list->{id};

	my $response =  $self->put("$api/cards/"+$card->{id}, $arguments);
	if ($response->code != 200) {
		return 0;
	}

	return 1;
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
