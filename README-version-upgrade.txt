Changes to apply when changing version:

- VERSION.txt: validate version number

- CHANGELOG

- Preliminary checking of web page doc otherwise everything has to be repeated: 
  * run tools/update-web.sh
  * this runs h 'make web' , which runs 'make webapi' 

- Generate a release :
    make release

  The following updates are done automatically:
  * man page (man make target)  --> via Makefile rule
  * updates download page (web_download make target) --> via ARCV HOOK
  
  NOTE: since some files may be updated:
    av -y
    make release

- Run all tests

- Tag the release once the release has been successfully tested:
    av pub
    The following updates are done automatically if 'av hook tools/update-web.sh' was called
    * online documentation update
      [x] make web is called
      [x] web site page are regenerated using make gensiten (release)

- Export the release to GitHub, for example (change to the actual version number):
  #av export ../release/shellapi/shellapi-1.1-3 # OLD WHEN NOT UNDER GPL
  av export . # New for LGPL

- Update GitHub: create the tag and related release packages manually

