#!/usr/bin/env ruby


#SCHOLAR_QUERY_URL = ScholarConf.SCHOLAR_SITE + '/scholar?' \

# as_q=%(words)s
# &as_epq=%(phrase)s
# &as_oq=%(words_some)s
# &as_eq=%(words_none)s

# any|title
# &as_occt=%(scope)s
# &as_sauthors=%(authors)s
# &as_publication=%(pub)s
# &as_ylo=%(ylo)s
# &as_yhi=%(yhi)s
# &as_vis=%(citations)s
# &btnG=&hl=en
# %(num)s
# &as_sdt=%(patents)s%%2C5

newwindow=1
num=20


https://scholar.google.it/scholar
?
as_occt=any
&
as_sauthors=AUTHOR
&
as_publication=PUBLISHED
&
as_ylo=1970
&
as_yhi=2017
&
btnG=
&
hl=it
&
as_sdt=0%2C5


