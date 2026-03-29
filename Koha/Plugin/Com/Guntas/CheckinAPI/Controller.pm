package Koha::Plugin::Com::Guntas::CheckinAPI::Controller;

use Modern::Perl;
use Mojo::Base 'Mojolicious::Controller';
use C4::Circulation;
use Koha::DateUtils qw( dt_from_string );
use Try::Tiny;

sub custom_checkin {
    my $c = shift;

    # 1. Authenticate first
    my $user = $c->authenticate;
    return unless $user;

    # 2. Validate OpenAPI input
    my $v = $c->openapi->valid_input or return;

    my $barcode;

    return try {
        my $body = $c->req->json;
        $barcode = $body->{barcode};
        
        my $branch     = $body->{branch};
        my $exemptfine = $body->{exemptfine} // 0;
        my $dropbox    = $body->{dropbox}    // 0;
        my $returndate = $body->{returndate} ? dt_from_string($body->{returndate}) : undef;

        my ($messages, $iteminformation, $borrower) = C4::Circulation::AddReturn(
            $barcode, 
            $branch, 
            $exemptfine, 
            $dropbox, 
            $returndate
        );

        # Handle Bad Barcode
        if ($messages->{BadBarcode}) {
            return $c->render(
                status  => 400,
                openapi => { error => "Invalid barcode: $barcode" }
            );
        }

        return $c->render(
            status  => 200, 
            openapi => { 
                status   => "success", 
                item     => ($iteminformation && $iteminformation->{title}) ? $iteminformation->{title} : "Unknown",
                messages => $messages // {}
            }
        );
    } 
    catch {
        my $err = $_;

        return $c->render(
            status  => 500,
            openapi => { 
                error   => "Checkin failed for barcode: $barcode",
                details => "$err" 
            }
        );
    };
}

1;