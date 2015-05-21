c
c $Id: nosinf.f,v 1.8 2008-11-20 10:51:34 georg Exp $
c
c revision log :
c
c 18.11.1998    ggu     check dimensions with dimnos
c 06.04.1999    ggu     some cosmetic changes
c 03.12.2001    ggu     some extra output -> place of min/max
c 09.12.2003    ggu     check for NaN introduced
c 07.03.2007    ggu     easier call
c 08.11.2008    ggu     do not compute min/max in non-existing layers
c 07.12.2010    ggu     write statistics on depth distribution (depth_stats)
c
c**************************************************************

	program nosinf

	use clo

c reads nos file

	implicit none

	include 'param.h'

	real cv(nkndim)
	real cv3(nlvdim,nkndim)

	integer ilhkv(nkndim)
	real hlv(nlvdim)
	real hev(neldim)

	logical bwrite,bquiet,bask,bmem
	logical bdate
	integer date,time
	integer nread,nin
	integer nvers
	integer nkn,nel,nlv,nvar
	integer ierr
	integer it,ivar
	integer l,k,lmax
	character*80 title
	character*20 dline
	character*80 infile
	character*80 basin,simul
	real rnull
	real cmin,cmax,caver

	integer iapini
	integer ifem_open_file

c--------------------------------------------------------------

	nread=0
	rnull=0.
	rnull=-1.

c--------------------------------------------------------------
c open basin and simulation
c--------------------------------------------------------------

        call clo_init('nosinf','nos-file','2.0')

        call clo_add_info('returns info on a nos file')

        call clo_add_option('mem',.false.,'if no file given use memory')
        call clo_add_option('ask',.false.,'ask for simulation')
        call clo_add_option('write',.false.,'write min/max of values')
        call clo_add_option('quiet',.false.,'do not be verbose')

        call clo_parse_options

        call clo_get_option('mem',bmem)
        call clo_get_option('ask',bask)
        call clo_get_option('write',bwrite)
        call clo_get_option('quiet',bquiet)

	if( .not. bask .and. .not. bmem ) call clo_check_files(1)
	call clo_get_file(1,infile)
	call ap_set_names(' ',infile)
	!write(6,*) 'infile: ',infile

	if( .not. bquiet ) then
	  call shyfem_copyright('nosinf - Info on NOS files')
	end if

	call ap_init(bask,2,nkndim,neldim)

	call open_nos_type('.nos','old',nin)

	call read_nos_header(nin,nkndim,neldim,nlvdim,ilhkv,hlv,hev)
	call nos_get_params(nin,nkn,nel,nlv,nvar)
	call nos_get_date(nin,date,time)
	bdate = date .gt. 0
	if( bdate ) call dtsini(date,time)

	call depth_stats(nkn,ilhkv)

c--------------------------------------------------------------
c loop on data
c--------------------------------------------------------------

	do while(.true.)

	  call nos_read_record(nin,it,ivar,nlvdim,ilhkv,cv3,ierr)

          if(ierr.gt.0) write(6,*) 'error in reading file : ',ierr
          if(ierr.ne.0) goto 100

	  nread=nread+1
	  if( .not. bquiet ) then
	    if( bdate ) then
	      call dtsgf(it,dline)
	      write(6,*) 'time : ',it,'  ',dline,'   ivar : ',ivar
	    else
	      write(6,*) 'time : ',it,'   ivar : ',ivar
	    end if
	  end if

	  if( bwrite ) then
	    do l=1,nlv
	      do k=1,nkn
	        cv(k)=cv3(l,k)
	        !if( cv(k) .gt. 1.e+6 ) write(6,*) 'max: ',k,l,cv(k)
	        if( l .gt. ilhkv(k) ) cv(k) = rnull
	      end do
	      call mimar(cv,nkn,cmin,cmax,rnull)
              call aver(cv,nkn,caver,rnull)
              call check1Dr(nkn,cv,0.,-1.,"NaN check","cv")
	      write(6,*) 'l,min,max,aver : ',l,cmin,cmax,caver
	    end do
	  end if

	end do	!do while

c--------------------------------------------------------------
c end of loop on data
c--------------------------------------------------------------

  100	continue

	write(6,*)
	write(6,*) nread,' records read'
	write(6,*)

	call ap_get_names(basin,simul)
	write(6,*) 'names used: '
	write(6,*) 'basin: ',trim(basin)
	write(6,*) 'simul: ',trim(simul)

c--------------------------------------------------------------
c end of routine
c--------------------------------------------------------------

	end

c***************************************************************

        subroutine aver(xx,n,xaver,rnull)

c computes min/max of vector
c
c xx            vector
c n             dimension of vector
c xmin,xmax     min/max value in vector
c rnull		invalid value

        implicit none

        integer n
        real xx(n)
        real xaver,rnull

	integer i,nacu
	double precision acu

	nacu = 0
	acu = 0.
	xaver = rnull

	do i=1,n
	  if(xx(i).ne.rnull) then
	    acu = acu + xx(i)
	    nacu = nacu + 1
	  end if
	end do

	if( nacu .gt. 0 ) xaver = acu / nacu

	end

c***************************************************************

        subroutine mimar(xx,n,xmin,xmax,rnull)

c computes min/max of vector
c
c xx            vector
c n             dimension of vector
c xmin,xmax     min/max value in vector
c rnull		invalid value

        implicit none

        integer n,i,nmin
        real xx(n)
        real xmin,xmax,x,rnull

	do i=1,n
	  if(xx(i).ne.rnull) goto 1
	end do
    1	continue

	if(i.le.n) then
	  xmax=xx(i)
	  xmin=xx(i)
	else
	  xmax=rnull
	  xmin=rnull
	end if

	nmin=i+1

        do i=nmin,n
          x=xx(i)
	  if(x.ne.rnull) then
            if(x.gt.xmax) xmax=x
            if(x.lt.xmin) xmin=x
	  end if
        end do

        end

c***************************************************************

        subroutine mimar_s(xx,nlvdim,n,xmin,xmax,rnull)

c computes min/max of vector
c
c xx            vector
c n             dimension of vector
c xmin,xmax     min/max value in vector
c rnull		invalid value

        implicit none

        integer n
        integer nlvdim
        real xx(nlvdim,n)
        real xmin,xmax,rnull

        integer k,l
        real x

        do k=1,n
          do l=1,nlvdim
            x=xx(l,k)
	    if(x.ne.rnull) then
              if( x .lt. xmin .or. x .gt. xmax ) then
                write(6,*) l,k,x
              end if
	    end if
          end do
        end do

        end

c***************************************************************

	subroutine depth_stats(nkn,ilhkv)

c	computes statistics on levels

	implicit none

	include 'param.h'

	integer nkn
	integer ilhkv(1)

	integer count(nlvdim)
	integer ccount(nlvdim)

	integer nlv,lmax,l,k,nc,ll

	nlv = 0
	do l=1,nlvdim
	  count(l) = 0
	  ccount(l) = 0
	end do

	do k=1,nkn
	  lmax = ilhkv(k)
	  if( lmax .gt. nlvdim ) stop 'error stop depth_stats: lmax'
	  count(lmax) = count(lmax) + 1
	  nlv = max(nlv,lmax)
	end do

	do l=nlv,1,-1
	  nc = count(l)
	  do ll=1,l
	    ccount(ll) = ccount(ll) + nc
	  end do
	end do

	nc = 0
	write(6,*) 'statistics for layers: ',nlv
	do l=1,nlv
	  if( count(l) > 0 ) then
	    write(6,*) l,count(l),ccount(l)
	    nc = nc + count(l)
	  end if
	end do
	write(6,*) 'total count: ',nc

	end

c***************************************************************

