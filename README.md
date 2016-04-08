###*Current Version: 1.0.0*###
# README #
I created this Vimscript _(adopted from `kde-devel-vim`)_ for myself to be a more generic C++ helper script _(not so KDE/Qt specific)_. I want to give full credit to the original authors so I added a header in the script file with the original writeup and a link to the location where I found it.

My main goals for this script when I started modifying the original were to add:

1. Maintenance free `makeprog` setup which supported "out-of-source-builds".

2. Maintenance free `tagfile` creation.

3. Help me stay consistent with my indent/coding style (K&R-ish). *The original had some formatting helpers and this was a big shortcut for me*


## Functionality provided by this script ##
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
    git clone https://bitbucket.org/JohnKaul/cpp-devel-vim.git
    vim -u NONE -c "helptags cpp-devel-vim/doc" -c q

Otherwise you can always download [version 1.0.0](https://bitbucket.org/JohnKaul/cpp-devel-vim/downloads/cpp-devel-vim_v1.0.0.tar.gz) and extract it manually (FYI: the `cpp-devel-vim.vim` file is supposed to be in your vim `plugin` directory).


### Contribution guidelines ###
* Contribute? Please. Feel free. My current needs are documentation, code checking and testing.
* Code review? Yes, please.
* Comments? Yes, please.

### Who do I talk to? ###

* John Kaul - john.kaul@outlook.com