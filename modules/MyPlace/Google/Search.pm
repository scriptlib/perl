package MyPlace::Google::Search;
use MyPlace::Google::Search::HTML;

sub search_images {
    return MyPlace::Google::Search::HTML::search_images(@_);
}

1;
