-- phpmyadmin_user_and_privileges.sql

CREATE USER 'phpmyadmin'@'localhost' IDENTIFIED BY 'HelloDude@1234';
GRANT USAGE ON mysql.* TO 'phpmyadmin'@'localhost';
GRANT SELECT (
    Host, User, Select_priv, Insert_priv, Update_priv, Delete_priv,
    Create_priv, Drop_priv, Reload_priv, Shutdown_priv, Process_priv,
    File_priv, Grant_priv, References_priv, Index_priv, Alter_priv,
    Show_db_priv, Super_priv, Create_tmp_table_priv, Lock_tables_priv,
    Execute_priv, Repl_slave_priv, Repl_client_priv
    ) ON mysql.user TO 'phpmyadmin'@'localhost';
GRANT SELECT ON mysql.db TO 'phpmyadmin'@'localhost';
GRANT SELECT (Host, Db, User, Table_name, Table_priv, Column_priv)
    ON mysql.tables_priv TO 'phpmyadmin'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE, ALTER ON phpmyadmin.* TO 'phpmyadmin'@'localhost';

