!
! tree utility routines
!
! still to do: implement tree for string
!
!===============================================================
	module tree
!===============================================================

	implicit none

	private

        type :: entry
          integer :: parent
          integer :: left
          integer :: right
          integer :: key
          integer :: info
        end type entry

        integer, parameter ::     no_type = 0
        integer, parameter ::  value_type = 1
        integer, parameter :: string_type = 2

        integer, parameter :: empty_error = 1
        integer, parameter ::  type_error = 2

        integer, save :: idlast = 0
        integer, save :: ndim = 0
        integer, parameter :: ndim_first = 5
        type(entry), save, allocatable :: pentry(:)

	public :: tree_init		!call tree_init(id)
	public :: tree_delete		!call tree_delete(id)

	public :: tree_push		!call tree_push(id,value)
	public :: tree_pop		!logical tree_pop(id,value)
	public :: tree_peek		!logical tree_peek(id,value)
	public :: tree_is_empty	!logical tree_is_empty(id)
	public :: tree_info		!call tree_info(id)

        INTERFACE tree_push
        MODULE PROCEDURE         tree_push_d
     +                          ,tree_push_r
     +                          ,tree_push_i
        END INTERFACE

        INTERFACE tree_pop
        MODULE PROCEDURE         tree_pop_d
     +                          ,tree_pop_r
     +                          ,tree_pop_i
        END INTERFACE

        INTERFACE tree_peek
        MODULE PROCEDURE         tree_peek_d
     +                          ,tree_peek_r
     +                          ,tree_peek_i
        END INTERFACE

!===============================================================
	contains
!===============================================================

        subroutine tree_init_alloc

        type(entry), allocatable :: paux(:)

        if( ndim == 0 ) then
          ndim = ndim_first
          allocate(pentry(ndim))
        else
          ndim = ndim*2
          allocate(paux(ndim))
          paux(1:ndim/2) = pentry(1:ndim/2)
          call move_alloc(paux,pentry)
        end if

        end subroutine tree_init_alloc

!******************************************************************

        subroutine tree_init_new_id(id)

        integer id

        idlast = idlast + 1
        if( idlast > ndim ) then
          call tree_init_alloc
        end if
        id = idlast

        call tree_init_id(id)

        end subroutine tree_init_new_id

!******************************************************************

        subroutine tree_init_id(id)

        integer id

        if( id > ndim ) then
          stop 'error stop tree_init_id: ndim'
        end if

        pentry(id)%parent = 0
        pentry(id)%max = 0
        pentry(id)%type = 0

	if( allocated(pentry(id)%array) ) deallocate(pentry(id)%array)
	if( allocated(pentry(id)%string) ) deallocate(pentry(id)%string)

        end subroutine tree_init_id

!******************************************************************

	subroutine tree_error(id,error)

	integer id,error

	if( error == empty_error ) then
	  write(6,*) 'tree: ',id
	  stop 'error stop tree: tree is empty'
	else if( error == type_error ) then
	  write(6,*) 'tree: ',id
	  write(6,*) 'type: ',pentry(id)%type
	  stop 'error stop tree: variable is of wrong type'
	else
	  stop 'error stop tree: internal error (1)'
	end if

	end subroutine tree_error

!******************************************************************

	subroutine realloc_double(n,value)

	integer n
	double precision, allocatable :: value(:)

	integer nsize
	double precision, allocatable :: daux(:)

	if( n == 0 ) then
	  n = 10
	  allocate(value(n))
	else
	  nsize = min(n,size(value))
          allocate(daux(n))
          daux(1:nsize) = value(1:nsize)
          call move_alloc(daux,value)
	end if

	end subroutine realloc_double

!******************************************************************
!******************************************************************
!******************************************************************

	subroutine tree_init(id)
	integer id
        call tree_init_new_id(id)
	end subroutine tree_init

	subroutine tree_delete(id)
	integer id
        call tree_init_id(id)
	if( id == idlast ) idlast = idlast - 1
	end subroutine tree_delete

!--------------------

	subroutine stack_push_i(id,value)
	integer id
	integer value
	call stack_push_d(id,dble(value))
	end subroutine stack_push_i

	subroutine stack_push_r(id,value)
	integer id
	real value
	call stack_push_d(id,dble(value))
	end subroutine stack_push_r

	subroutine stack_push_d(id,value)
	integer id
	double precision value
	integer n
	if( pentry(id)%top >= pentry(id)%max ) then
	  n = 2 * pentry(id)%max
	  call realloc_double(n,pentry(id)%array)
	  pentry(id)%max = n
	end if
	if( pentry(id)%type == no_type ) then
	  pentry(id)%type = value_type
	end if
	if( pentry(id)%type /= value_type ) then
	  call stack_error(id,type_error)
	end if
	pentry(id)%top = pentry(id)%top + 1
	pentry(id)%array(pentry(id)%top) = value
	end subroutine stack_push_d

!--------------------

	logical function stack_pop_i(id,value)
	integer id
	integer value
	double precision dvalue
	stack_pop_i = stack_pop_d(id,dvalue)
	value = nint(dvalue)
	end function stack_pop_i

	logical function stack_pop_r(id,value)
	integer id
	real value
	double precision dvalue
	stack_pop_r = stack_pop_d(id,dvalue)
	value = real(dvalue)
	end function stack_pop_r

	logical function stack_pop_d(id,value)
	integer id
	double precision value
	stack_pop_d = stack_peek_d(id,value)
	if( stack_pop_d ) pentry(id)%top = pentry(id)%top - 1
	end function stack_pop_d

!--------------------

	logical function stack_peek_i(id,value)
	integer id
	integer value
	double precision dvalue
	stack_peek_i = stack_peek_d(id,dvalue)
	value = nint(dvalue)
	end function stack_peek_i

	logical function stack_peek_r(id,value)
	integer id
	real value
	double precision dvalue
	stack_peek_r = stack_peek_d(id,dvalue)
	value = real(dvalue)
	end function stack_peek_r

	logical function stack_peek_d(id,value)
	integer id
	double precision value
	stack_peek_d = .false.
	if( pentry(id)%top == 0 ) return
	if( pentry(id)%type /= value_type ) then
	  call stack_error(id,type_error)
	end if
	value = pentry(id)%array(pentry(id)%top)
	stack_peek_d = .true.
	end function stack_peek_d

!--------------------

	logical function stack_is_empty(id)
	integer id
	stack_is_empty = ( pentry(id)%top == 0 )
	end function stack_is_empty

!--------------------

	subroutine stack_info(id)
	integer id
	write(6,*) 'stack_info: ',id,pentry(id)%top
     +			,pentry(id)%max,pentry(id)%type
	end subroutine stack_info

!===============================================================
	end module
!===============================================================

	subroutine stack_test

	use stack

	implicit none

	integer, parameter :: ndim = 100
	integer, parameter :: nloop = 10000
	integer, allocatable :: vals(:)
	integer val,value,nl,n,i,id,ind,nop
	logical bdebug
	real r

	bdebug = .true.
	bdebug = .false.

	call stack_init(id)
	allocate(vals(ndim))

	call random_seed
	val = 0
	ind = 0
	nop = 0

	do nl=1,nloop
	  call stack_rand_int(1,10,n)
	  if( bdebug ) write(6,*) 'push values: ',n
	  do i = 1,n
	    val = val + 1
	    !write(6,*) 'push: ',val
	    call stack_push(id,val)
	    ind = ind + 1
	    call stack_assert(ind <= ndim,'push',id)
	    vals(ind) = val
	  end do
	  nop = nop + n
	  call stack_rand_int(1,15,n)
	  if( bdebug ) write(6,*) 'pop values: ',n
	  do i = 1,n
	    if( stack_pop(id,value) ) then
	      !write(6,*) 'pop: ',value
	      call stack_assert(ind > 0,'pop empty',id)
	      call stack_assert(value==vals(ind),'pop value',id)
	      ind = ind - 1
	      nop = nop + 1
	    else
	      if( bdebug ) write(6,*) 'nothing to pop'
	      call stack_assert(ind == 0,'pop not empty',id)
	      exit
	    end if
	  end do
	end do

	call stack_delete(id)

	write(6,*) 'stack test successfully finished: ',nloop,nop,val

	end

!******************************************************************

        subroutine stack_assert(bcheck,text,id)
        use stack
        implicit none
        logical bcheck
        character*(*) text
        integer id
        if( .not. bcheck ) then
          write(6,*) 'stack_assertion: ',trim(text)
          call stack_info(id)
          stop 'assertion failed'
        end if
        end

	subroutine stack_rand_int(min,max,irand)

	implicit none
	integer min,max
	integer irand
	real r

	call random_number(r)
	irand = min + (max-min+1)*r

	end

!******************************************************************

	programme stack_main
	call stack_test
	end programme stack_main

!******************************************************************