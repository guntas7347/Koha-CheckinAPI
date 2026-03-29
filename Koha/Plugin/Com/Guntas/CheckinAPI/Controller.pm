package Koha::Plugin::Com::Guntas::CheckinAPI::Controller;

use Modern::Perl;
use Mojo::Base 'Mojolicious::Controller';
use C4::Circulation;
use Koha::DateUtils qw( dt_from_string );
use Try::Tiny;

sub custom_checkin {
    my $c = shift;

    # 1. Validate OpenAPI Input
    # This automatically rejects bad JSON or missing required fields (like 'branch')
    my $v = $c->openapi->valid_input or return;

    my $barcode;
    return try {
        my $body    = $c->req->json;
        $barcode    = $body->{barcode};
        my $branch  = $body->{branch};
        
        # Optional fields with defaults
        my $exemptfine = $body->{exemptfine} // 0;
        my $dropbox    = $body->{dropbox}    // 0;
        my $returndate = $body->{returndate} ? dt_from_string($body->{returndate}) : undef;

        # 2. Proceed with AddReturn
        # FIXED: Catching all 4 return values to prevent the "0 as HASH ref" crash
        my ($doreturn, $messages, $iteminfo, $borrower) = C4::Circulation::AddReturn(
            $barcode, $branch, $exemptfine, $dropbox, $returndate
        );

        # 3. Handle Logical Errors (e.g., Barcode doesn't exist in DB)
        if ($messages && $messages->{BadBarcode}) {
            return $c->render(
                status  => 400,
                openapi => {
                    error      => "Invalid barcode: $barcode",
                    error_code => "INVALID_BARCODE"
                }
            );
        }

        # 4. Success!
        return $c->render(
            status  => 200,
            openapi => {
                messages        => $messages // {},
                iteminformation => $iteminfo // {},
                borrower        => $borrower // {}
            }
        );

    } catch {
        my $err = $_;
        
        
        return $c->render(
            status  => 500,
            openapi => {
                error      => "Internal Server Error",
                error_code => "INTERNAL_ERROR",
                details    => "$err"
            }
        );
    };
}

1;