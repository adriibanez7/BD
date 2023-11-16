create table departments
(
    dept_no   char(4)     not null
        primary key,
    dept_name varchar(40) not null,
    constraint dept_name
        unique (dept_name)
);

create table employees
(
    emp_no     int             not null
        primary key,
    birth_date date            not null,
    first_name varchar(14)     not null,
    last_name  varchar(16)     not null,
    gender     enum ('M', 'F') not null,
    hire_date  date            not null
);

create table bajas_medicas
(
    PK_ID_BAJAS_MEDICAS int auto_increment
        primary key,
    emp_no              int                                                             null,
    fecha_inicio        date                                                            not null,
    fecha_fin           date                                                            not null,
    certificado_medico  varchar(255)                                                    null,
    estado              enum ('aprobado', 'pendiente', 'rechazado') default 'pendiente' null,
    constraint bajas_medicas_ibfk_1
        foreign key (emp_no) references employees (emp_no)
            on delete cascade
);

create index emp_no
    on bajas_medicas (emp_no);

create table dept_emp
(
    emp_no    int     not null,
    dept_no   char(4) not null,
    from_date date    not null,
    to_date   date    not null,
    primary key (emp_no, dept_no),
    constraint dept_emp_ibfk_1
        foreign key (emp_no) references employees (emp_no)
            on delete cascade,
    constraint dept_emp_ibfk_2
        foreign key (dept_no) references departments (dept_no)
            on delete cascade
);

create index idx_dept_emp_dept_no
    on dept_emp (dept_no);

create index idx_dept_emp_to_date
    on dept_emp (to_date);

create definer = root@`%` trigger insert_dept_emp__trigger
    before insert
    on dept_emp
    for each row
BEGIN
	IF count(*) > 10 THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'EL límite de empleados del departamento es 10, y se ha excedido';
	ELSE
	SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Departamento modificado con éxito';
	END IF;
END;

create table dept_manager
(
    emp_no    int     not null,
    dept_no   char(4) not null,
    from_date date    not null,
    to_date   date    not null,
    primary key (emp_no, dept_no),
    constraint dept_manager_ibfk_1
        foreign key (emp_no) references employees (emp_no)
            on delete cascade,
    constraint dept_manager_ibfk_2
        foreign key (dept_no) references departments (dept_no)
            on delete cascade
);

create index dept_no
    on dept_manager (dept_no);

create table documentos_firmados
(
    PK_ID_DOCUMENTOS_FIRMADOS int auto_increment
        primary key,
    emp_no                    int          null,
    nombre                    varchar(255) null,
    fecha_documento_firmado   date         not null,
    constraint documentos_firmados_ibfk_1
        foreign key (emp_no) references employees (emp_no)
            on delete cascade
);

create index emp_no
    on documentos_firmados (emp_no);

create index idx_employees_emp_no
    on employees (emp_no);

create table historial_promociones
(
    id_promocion    int auto_increment
        primary key,
    emp_no          int         not null,
    antiguo_titulo  varchar(50) not null,
    nuevo_titulo    varchar(50) not null,
    fecha_promocion date        not null,
    constraint historial_promociones_ibfk_1
        foreign key (emp_no) references employees (emp_no)
            on delete cascade
);

create index emp_no
    on historial_promociones (emp_no);

create table historial_salarios
(
    emp_no                   int       not null,
    PK_id_historial_salarios int auto_increment
        primary key,
    fecha_update             timestamp not null,
    nuevo_salario            int       not null,
    from_date                date      not null,
    to_date                  date      not null,
    constraint historial_salarios_FK
        foreign key (emp_no) references employees (emp_no)
);

create table notificationes_cumpleaños
(
    PK_ID_NOTIFICACION int auto_increment
        primary key,
    emp_no             int          not null,
    fecha_notificacion date         not null,
    mensaje            varchar(255) not null,
    constraint notificationes_cumpleaños_ibfk_1
        foreign key (emp_no) references employees (emp_no)
            on delete cascade
);

create index emp_no
    on notificationes_cumpleaños (emp_no);

create table salaries
(
    emp_no    int  not null,
    salary    int  not null,
    from_date date not null,
    to_date   date not null,
    primary key (emp_no, from_date),
    constraint salaries_ibfk_1
        foreign key (emp_no) references employees (emp_no)
            on delete cascade
);

create index idx_salaries_emp_no
    on salaries (emp_no);

create definer = root@`%` trigger update_salary_empleado
    after update
    on salaries
    for each row
BEGIN
		INSERT INTO employees.historial_salarios (emp_no,fecha_update,nuevo_salario,from_date,to_date) VALUES (OLD.emp_no,NOW(),NEW.salary,OLD.from_date,OLD.to_date);
	END;

create table titles
(
    emp_no    int         not null,
    title     varchar(50) not null,
    from_date date        not null,
    to_date   date        null,
    primary key (emp_no, title, from_date),
    constraint titles_ibfk_1
        foreign key (emp_no) references employees (emp_no)
            on delete cascade
);

create table vacaciones
(
    PK_ID_VACACIONES int auto_increment
        primary key,
    emp_no           int                                                             null,
    fecha_inicio     date                                                            not null,
    fecha_fin        date                                                            not null,
    estado           enum ('aprobado', 'pendiente', 'rechazado') default 'pendiente' null,
    constraint vacaciones_ibfk_1
        foreign key (emp_no) references employees (emp_no)
            on delete cascade
);

create index emp_no
    on vacaciones (emp_no);

create definer = root@`%` view current_dept_emp as
select `employees`.`l`.`emp_no`    AS `emp_no`,
       `d`.`dept_no`               AS `dept_no`,
       `employees`.`l`.`from_date` AS `from_date`,
       `employees`.`l`.`to_date`   AS `to_date`
from (`employees`.`dept_emp` `d` join `employees`.`dept_emp_latest_date` `l`
      on (((`d`.`emp_no` = `employees`.`l`.`emp_no`) and (`d`.`from_date` = `employees`.`l`.`from_date`) and
           (`employees`.`l`.`to_date` = `d`.`to_date`))));

create definer = root@`%` view dept_emp_latest_date as
select `employees`.`dept_emp`.`emp_no`         AS `emp_no`,
       max(`employees`.`dept_emp`.`from_date`) AS `from_date`,
       max(`employees`.`dept_emp`.`to_date`)   AS `to_date`
from `employees`.`dept_emp`
group by `employees`.`dept_emp`.`emp_no`;

create
    definer = root@`%` procedure generar_informe_rendimiento()
BEGIN
    DECLARE salario_promedio DECIMAL(10, 2);
    SELECT AVG(salary) INTO salario_promedio FROM employees.salaries;

   SELECT 'Salario Promedio:', salario_promedio AS Resultado;

    SELECT dept_no , COUNT(*) AS cantidad_empleados
    FROM employees.dept_emp
    GROUP BY dept_no;

   SELECT 'Salario Máximo:', MAX(salary) AS salario_maximo FROM employees.salaries;
    SELECT 'Salario Mínimo:', MIN(salary) AS salario_minimo FROM employees.salaries;

    SELECT 'Cantidad de Empleados por Género:', gender, COUNT(*) AS cantidad_empleados
    FROM employees
    GROUP BY gender;


END;

create
    definer = root@`%` procedure notificar_cumpleaños()
BEGIN
    DECLARE emp_id INT;

    DECLARE birthday_cursor CURSOR FOR
        SELECT emp_no
        FROM employees
        WHERE MONTH(birth_date) = MONTH(CURDATE()) AND DAYOFMONTH(birth_date) = DAYOFMONTH(CURDATE());

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET emp_id = NULL;

    OPEN birthday_cursor;

    birthday_loop: LOOP
        FETCH birthday_cursor INTO emp_id;

        IF emp_id IS NULL THEN
            LEAVE birthday_loop;
        END IF;

        INSERT INTO notificationes_cumpleaños (emp_no, mensaje, fecha_notificacion)
        VALUES (emp_id, CONCAT('¡','Feliz Cumpleaños , ', (SELECT CONCAT(first_name,' ', last_name) FROM employees WHERE emp_no = emp_id), '!'), CURDATE());
    END LOOP;

    CLOSE birthday_cursor;
END;

create
    definer = root@`%` procedure promocion_empleado(IN emp_id int, IN new_title varchar(50))
BEGIN
    DECLARE current_title VARCHAR(50);

    SELECT title INTO current_title
    FROM employees.titles
    WHERE emp_no = emp_id AND to_date = '9999-01-01';

    UPDATE employees.titles
    SET to_date = CURDATE()
    WHERE emp_no = emp_id AND to_date = '9999-01-01';

    INSERT INTO employees.titles (emp_no, title, from_date, to_date)
    VALUES (emp_id, new_title, CURDATE(), '9999-01-01');

    INSERT INTO employees.historial_promociones (emp_no, antiguo_titulo, nuevo_titulo, fecha_promocion)
    VALUES (emp_id, current_title, new_title, CURDATE());
END;

create definer = root@`%` event evento_cumpleaños on schedule
    every '1' DAY
        starts '2023-11-15 06:00:00'
    enable
    do
    BEGIN
    CALL notificar_cumpleaños();
END;


