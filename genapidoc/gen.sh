#!/bin/bash
cat "$1" | awk '
function trimAnyLeft(s,c) { pat="^[" c "]+"; gsub(pat, "", s); return s; }
function trimAnySingleLeft(s,c) { pat="^" c "+"; gsub(pat, "", s); return s; }
function trimAnyRight(s,c) { pat="[" c "]+$" ; gsub(pat, "", s); return s; }
function trimLeft(s) { gsub(/^[ \t\r\n]+/, "", s); return s; }
function trimRight(s) { gsub(/[ \t\r\n]+$/, "", s); return s; }
function trim(s) { return trimRight(trimLeft(s));}
function trimAny(s,c) { return trimAnyRight(trimAnyLeft(s,c),c);}

BEGIN {
  commentStartMet=1;
  commentEndMet=1;
  doc="";
}

/^:<<'\''EOF'\''/ {
  commentStartMet=0;
  commentEndMet=1;
  next;
}

/^EOF/ {
  if (commentStartMet==0) {
    commentEndMet=0;
    next;
  }
}

/^[[:space:]]*[a-zA-Z0-9_-]+[[:space:]]*\([[:space:]]*\)[[:space:]]*{?[[:space:]]*$/ {
  s=$0;
  s=trimAnyRight(s," ")
  s=trimAnyRight(s,"{")
  s=trimAnyRight(s," ")
  s=trimAnyRight(s,")")
  s=trimAnyRight(s,"(")
  if ((commentStartMet==0) && (commentEndMet==0)) {
   print s " a| [%hardbreaks]" doc
   #print doc
   commentStartMet=1;
   commentEndMet=1;
   doc=""
   next
  }
}

/^[[:space:]]*$/ {
  # skip empty lines
  next
}

{
  if ((commentStartMet==0) && (commentEndMet==0)) {
   # This is a standalone comment without function signature following
   doc=""
   commentStartMet=1;
   commentEndMet=1;
   #print "WARNING: line " $0 " encountered while start comment and end comment was detected"
  }
  else if ((commentStartMet==0) && (commentEndMet==1)) {
     #print "WARNING: line $0 encountered while start comment detected but not  end comment was detected"
     if (length(doc)==0) doc=$0; else doc=doc "\\n" $0;
  }
  else
  {
   doc=""
   commentStartMet=1;
   commentEndMet=1;
  }

}

'
