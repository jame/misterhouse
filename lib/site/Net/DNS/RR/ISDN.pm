package Net::DNS::RR::ISDN;

# $Id$

use strict;
use vars qw(@ISA);

use Net::DNS::Packet;

@ISA = qw(Net::DNS::RR);

sub new {
	my ($class, $self, $data, $offset) = @_;

	if ($self->{"rdlength"} > 0) {
		my ($address, $sa, $len);

		($len) = unpack("\@$offset C", $$data);
		++$offset;
		$address = substr($$data, $offset, $len);
		$offset += $len;

		if ($len + 1 < $self->{"rdlength"}) {
			($len) = unpack("\@$offset C", $$data);
			++$offset;
			$sa = substr($$data, $offset, $len);
			$offset += $len;
		}
		else {
			$sa = "";
		}

		$self->{"address"} = $address;
		$self->{"sa"}  = $sa;
	}

	return bless $self, $class;
}

sub new_from_string {
	my ($class, $self, $string) = @_;

	if ($string && $string =~ /^['"](.*?)['"]/) {
		$self->{"address"} = $1;
		my $rest = $';

		if ($rest =~ /^\s+['"](.*?)['"]$/) {
			$self->{"sa"} = $1;
		}
		else {
			$self->{"sa"} = "";
		}
	}

	return bless $self, $class;
}

sub rdatastr {
	my $self = shift;

	return exists $self->{"address"}
	       ? qq("$self->{address}" "$self->{sa}")
	       : "; no data";
}

sub rr_rdata {
	my $self = shift;
	my $rdata = "";

	if (exists $self->{"address"}) {
		$rdata .= pack("C", length $self->{"address"});
		$rdata .= $self->{"address"};

		if ($self->{"sa"}) {
			$rdata .= pack("C", length $self->{"sa"});
			$rdata .= $self->{"sa"};
		}
	}

	return $rdata;
}

1;
__END__

=head1 NAME

Net::DNS::RR::ISDN - DNS ISDN resource record

=head1 SYNOPSIS

C<use Net::DNS::RR>;

=head1 DESCRIPTION

Class for DNS ISDN resource records.

=head1 METHODS

=head2 address

    print "address = ", $rr->address, "\n";

Returns the RR's address field.

=head2 sa

    print "subaddress = ", $rr->sa, "\n";

Returns the RR's subaddress field.

=head1 COPYRIGHT

Copyright (c) 1997 Michael Fuhr.  All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself. 

=head1 SEE ALSO

L<perl(1)>, L<Net::DNS>, L<Net::DNS::Resolver>, L<Net::DNS::Packet>,
L<Net::DNS::Header>, L<Net::DNS::Question>, L<Net::DNS::RR>,
RFC 1183 Section 3.2

=cut
