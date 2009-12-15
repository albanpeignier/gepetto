# Some useful defaults

Exec { path => "/usr/bin:/usr/sbin/:/bin:/sbin:/usr/local/bin:/usr/local/sbin" }

File { 
  ignore => ['.svn', '.git', 'CVS', '*~' ], 
  checksum => md5, 
  owner => root, group => root, 
  backup => server 
}

filebucket { server: server => puppet }
