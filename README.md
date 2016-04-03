# README #
This Vim script _(adopted from `kde-devel-vim`)_ will become a more generic C++ helper script _(not so KDE/Qt specific)_. I want to give full credit to the original authors so I will add a header in the script file with a link to the original. I also don't want to clutter the file with commented out code/lines so I will be deleting them as they become unnecessary or replaced.

## Functionality provided ##
*  Automatic brace and parenthesis addition. _Intelligence added to place braces on same line as `if`,`while`,`do`,etc._
*  Automatic space between keyword and paren addition.
*  Quick switching between header and impl file.
*  Intelligent includes additions. _EG: Automatic `#include <string.h>` statement when cursor is on `std::string` statement._
*  Ability to add "standard" (to be overridden for personal or project
   stds) comment headers.
*  Change and TODO log entry helpers.
*  (un)comment line toggle. _This feature also works with visual selection as well._
*  Intelligent directory searching to enable "out-of-source-building", like
   in the use of CMAKE.
*  Generic tab completion for braces, parenthesis and quotes. _This feature is only meant for convinces, please use a mechanism like "SnipMate" for better tab completion._
*  Ability to align assignments in surrounding statements.
*  Automatic tagfile write for better project source code navigation.
*  Automatic 'path' setting for 'gf' command navigation.
*  Custom 'Make()' function/command to support better
   out-of-source-building; this should build the project from any source
   code file in the project.

### How do I get set up? ###
If you don't have a preferred installation method, I recommend installing [pathogen.vim](https://github.com/tpope/vim-pathogen), and then simply copy and paste:

    cd ~/.vim/bundle
    git clone https://JohnKaul@bitbucket.org/JohnKaul/cpp-devel-vim.git

Otherwise you can always download this and place the `cpp-devel-vim.vim` file in the `plugin` directory. 

### Contribution guidelines ###
* Contribute? Please. Feel free. My current needs are documentation, code checking and testing.
* Code review? Yes, please.
* Comments? Yes, please.

### Who do I talk to? ###

* John Kaul - john.kaul@outlook.com