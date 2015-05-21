c
c $Id: adj575.f,v 1.5 2007-03-20 13:19:42 georg Exp $
c
c description :
c
c 5-7-5 grade routines
c
c contents :
c
c subroutine elim57(nkn,nel,ngrdim,ngrade,nbound,ngri,nen3v)
c			eliminates special 575 connections (shell)
c subroutine elim575(k,nkn,nel,ngrdim,ngrade,nbound,ngri,nen3v)
c			eliminates 5-7-5 connections
c
c***********************************************************

	subroutine elim57

c eliminates 5-7-5 grades

	implicit none

        include 'param.h'
        include 'basin.h'
        include 'grade.h'

        integer k,n

        write(6,*) 'eliminating grades for grade 5-7-5... '

        do k=1,nkn
          n = ngrade(k)
          if( n .eq. 7 .and. nbound(k) .eq. 0 ) then
            call elim575(k)
	    call chkgrd
          end if
        end do

	end

c***********************************************************

	subroutine elim575(k)

c eliminates 5-7-5 connections

	implicit none

        include 'param.h'
        include 'basin.h'
        include 'grade.h'

	integer k

	logical bdebug
        integer n,i,nc,ii
	integer ie,kk,iii
	integer ip1,ip2
	integer ip
	integer ng,idp
	integer ngav(ngrdim)
	integer ngrv(ngrdim)
	integer nbav(ngrdim)
	integer iau(ngrdim)
	real x,y,xm,ym

	if( k .gt. nkn ) return

	bdebug = .true.
	bdebug = .false.

	if( bdebug ) write(6,*) 'new node: ',k

c make list

        n = ngrade(k)
	do i=1,n
	  ngav(i) = ngri(i,k)
	end do

	do i=1,n
	  ngrv(i) = ngrade(ngav(i))
	  nbav(i) = 0
	  if( nbound(ngav(i)) .ne. 0 ) then
	    ngrv(i) = 6
	    nbav(i) = 1
	  end if
	end do

	if( bdebug ) then
	  do i=1,n
c	    write(6,*) ngav(i-1),ngav(i),ngav(i+1)
	  end do
	end if

c check if exchange is possible

	nc = 0
	do i=1,n
	  ng = ngrv(i)
	  if( ng .eq. 5 ) nc = nc + 1
	end do

	if( nc .ne. 2 ) return	!if not exactly 2 cannot proceed

c find out distance of 5 grades

	nc = 0
	ip1 = 0
	ip2 = 0
	do i=1,n
	  ng = ngrv(i)
	  if( ng .eq. 5 ) then
	    nc = nc + 1
	    if( nc .eq. 1 ) then
		ip1 = i
	    else
		ip2 = i
	    end if
	  end if
	end do

	idp = ip2 - ip1
	if( idp .le. 2 .or. idp .ge. 5 ) return

	write(6,*) k,nc,ip1,ip2

	if( bdebug ) then
	  write(6,*) ngav(ip1),ngav(ip2)
	  write(6,'(7i10)') (ngav(i),i=1,7)
	  write(6,'(7i10)') (ngrv(i),i=1,7)
	  write(6,'(7i10)') (nbav(i),i=1,7)
	end if

c	call plosno(k)

c reorder node list
c node 1 is a 5-grade, and node 5 is a 5-grade

	ip = ip1
	if( idp .eq. 3 ) ip = ip2
	call nshift(ip,n,ngav,iau)
	call nshift(ip,n,ngrv,iau)
	call nshift(ip,n,nbav,iau)

	if( bdebug ) then
	  write(6,'(7i10)') (ngav(i),i=1,7)
	  write(6,'(7i10)') (ngrv(i),i=1,7)
	  write(6,'(7i10)') (nbav(i),i=1,7)
	end if

c new node 

	call newnod(nkn)

c substitute new node for old one in node index

	do ie=1,nel
	  do ii=1,3
	    kk = nen3v(ii,ie)
	    if( kk .eq. k ) then
	      do iii=1,3
		if( nen3v(iii,ie) .eq. ngav(2) ) nen3v(ii,ie) = nkn
		if( nen3v(iii,ie) .eq. ngav(4) ) nen3v(ii,ie) = nkn
	      end do
	    end if
	  end do
	end do

c new elements

	call newele(nel)
	call setele(nel,ngav(1),nkn,k,nen3v)
	call newele(nel)
	call setele(nel,ngav(5),k,nkn,nen3v)

c adjust grade index of old node (5 grade)

	call delgr(k,ngav(2),ngrdim,ngrade,ngri)
	call delgr(k,ngav(3),ngrdim,ngrade,ngri)
	call delgr(k,ngav(4),ngrdim,ngrade,ngri)
	call insgr(k,ngav(1),nkn,ngrdim,ngrade,ngri)

c adjust grade index of new node (6 grade)

	do i=1,5
	  ngri(i,nkn) = ngav(i)
	end do
	ngri(6,nkn) = k
	ngrade(nkn) = 6

c adjust grade index of 5-5 nodes

	call insgrb(ngav(1),k,nkn,ngrdim,ngrade,ngri)
	call insgr(ngav(5),k,nkn,ngrdim,ngrade,ngri)

c substitute new node in grade index of nodes close to new node

	call exchgr(ngav(2),k,nkn,ngrdim,ngrade,ngri)
	call exchgr(ngav(3),k,nkn,ngrdim,ngrade,ngri)
	call exchgr(ngav(4),k,nkn,ngrdim,ngrade,ngri)

	if( bdebug ) then
	  call prgr(k,ngrdim,ngrade,ngri)
	  call prgr(nkn,ngrdim,ngrade,ngri)
	  call prgr(ngav(1),ngrdim,ngrade,ngri)
	  call prgr(ngav(5),ngrdim,ngrade,ngri)
	end if

c adjust coordinates

	xm = 0.5 * ( xgv(ngav(6)) + xgv(ngav(7)) )
	ym = 0.5 * ( ygv(ngav(6)) + ygv(ngav(7)) )
	x = xgv(ngav(3))
	y = ygv(ngav(3))

	xgv(k) = xm + (1./3.) * ( x - xm )
	ygv(k) = ym + (1./3.) * ( y - ym )
	xgv(nkn) = xm + (2./3.) * ( x - xm )
	ygv(nkn) = ym + (2./3.) * ( y - ym )

c	call plosel2(nel-1,nel)

	end

c*******************************************************
