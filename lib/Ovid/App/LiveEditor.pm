package Ovid::App::LiveEditor;

use v5.40;
use Dancer2;

our $VERSION = '0.1';

get '/' => sub {
    return "Hello World";
};

true;
