MODULE fields

  USE boundary

  IMPLICIT NONE

  REAL(num), DIMENSION(6) :: const
  INTEGER :: large, small, order
  REAL(num) :: hdt, fac
  REAL(num) :: hdtx
  REAL(num) :: cnx

CONTAINS

  SUBROUTINE set_field_order(field_order)

    INTEGER, INTENT(IN) :: field_order

    order = field_order
    large = order / 2
    small = large - 1
    fng = large

    IF (field_order .EQ. 2) THEN
      const(1:2) = (/ -1.0_num, 1.0_num /)
      cfl = 1.0_num
    ELSE IF (field_order .EQ. 4) THEN
      const(1:4) = (/ 1.0_num/24.0_num, -9.0_num/8.0_num, &
          9.0_num/8.0_num, -1.0_num/24.0_num /)
      cfl = 6.0_num / 7.0_num
    ELSE
      const(1:6) = (/ -3.0_num/640.0_num, 25.0_num/384.0_num, &
          -75.0_num/64.0_num, 75.0_num/64.0_num, -25.0_num/384.0_num, &
          3.0_num/640.0_num /)
      cfl = 120.0_num / 149.0_num
    ENDIF

  END SUBROUTINE set_field_order



  SUBROUTINE update_e_field

    INTEGER :: ix
    REAL(num) :: cpml_x, j_extra = 0

    IF (cpml_boundaries) THEN
      CALL cpml_advance_e_currents(0.5_num * dt)

      cpml_x = cnx

      DO ix = 1, nx
        ex(ix) = ex(ix) &
            - fac * jx(ix)
      ENDDO

      DO ix = 1, nx
        cpml_x = cnx / cpml_kappa_ex(ix)
        j_extra = cpml_psi_eyx(ix) / mu0
        ey(ix) = ey(ix) &
            - cpml_x * SUM(const(1:order) * bz(ix-large:ix+small)) &
            - fac * (jy(ix) + j_extra)
      ENDDO

      DO ix = 1, nx
        cpml_x = cnx / cpml_kappa_ex(ix)
        j_extra = -cpml_psi_ezx(ix) / mu0
        ez(ix) = ez(ix) &
            + cpml_x * SUM(const(1:order) * by(ix-large:ix+small)) &
            - fac * (jz(ix) + j_extra)
      ENDDO
    ELSE
      DO ix = 1, nx
        ex(ix) = ex(ix) &
            - fac * jx(ix)
      ENDDO

      DO ix = 1, nx
        ey(ix) = ey(ix) &
            - cnx * SUM(const(1:order) * bz(ix-large:ix+small)) &
            - fac * jy(ix)
      ENDDO

      DO ix = 1, nx
        ez(ix) = ez(ix) &
            + cnx * SUM(const(1:order) * by(ix-large:ix+small)) &
            - fac * jz(ix)
      ENDDO
    ENDIF

  END SUBROUTINE update_e_field



  SUBROUTINE update_b_field

    INTEGER :: ix
    REAL(num) :: cpml_x, j_extra = 0

    IF (cpml_boundaries) THEN
      CALL cpml_advance_b_currents(0.5_num * dt)

      cpml_x = hdtx

      DO ix = 1, nx
        cpml_x = hdtx / cpml_kappa_bx(ix)
        j_extra = -cpml_psi_byx(ix)
        by(ix) = by(ix) &
            + cpml_x * SUM(const(1:order) * ez(ix-small:ix+large)) &
            - hdt * j_extra
      ENDDO

      DO ix = 1, nx
        cpml_x = hdtx / cpml_kappa_bx(ix)
        j_extra = cpml_psi_bzx(ix)
        bz(ix) = bz(ix) &
            - cpml_x * SUM(const(1:order) * ey(ix-small:ix+large)) &
            - hdt * j_extra
      ENDDO
    ELSE
      DO ix = 1, nx
        by(ix) = by(ix) &
            + hdtx * SUM(const(1:order) * ez(ix-small:ix+large))
      ENDDO

      DO ix = 1, nx
        bz(ix) = bz(ix) &
            - hdtx * SUM(const(1:order) * ey(ix-small:ix+large))
      ENDDO
    ENDIF

  END SUBROUTINE update_b_field



  SUBROUTINE update_eb_fields_half

    hdt  = 0.5_num * dt
    hdtx = hdt / dx

    cnx = hdtx * c**2

    fac = hdt / epsilon0

    ! Update E field to t+dt/2
    CALL update_e_field

    ! Now have E(t+dt/2), do boundary conditions on E
    CALL efield_bcs

    ! Update B field to t+dt/2 using E(t+dt/2)
    CALL update_b_field

    ! Now have B field at t+dt/2. Do boundary conditions on B
    CALL bfield_bcs(.TRUE.)

    ! Now have E&B fields at t = t+dt/2
    ! Move to particle pusher

  END SUBROUTINE update_eb_fields_half



  SUBROUTINE update_eb_fields_final

    hdt  = 0.5_num * dt
    hdtx = hdt / dx

    cnx = hdtx * c**2

    fac = hdt / epsilon0

    CALL update_b_field

    CALL bfield_final_bcs

    CALL update_e_field

    CALL efield_bcs

  END SUBROUTINE update_eb_fields_final

END MODULE fields
