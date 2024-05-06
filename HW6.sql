/* Написать функцию, которая удаляет всю информацию об указанном пользователе из БД vk. 
* Пользователь задается по id. Удалить нужно все сообщения, 
* лайки, медиа записи, профиль и запись из таблицы users. 
* Функция должна возвращать номер пользователя. */
USE vk;

DROP FUNCTION IF EXISTS vk.delete_user;

DELIMITER ^^
CREATE FUNCTION delete_user (target_id BIGINT UNSIGNED)
RETURNS BIGINT READS SQL DATA 
BEGIN
	DELETE FROM messages 
	WHERE from_user_id = target_id 
	OR to_user_id = target_id;

	DELETE FROM likes 
	WHERE user_id = target_id 
	OR media_id IN (SELECT id FROM media 
		WHERE user_id = target_id);

	DELETE FROM users_communities
	WHERE user_id = target_id;

	DELETE FROM profiles
	WHERE user_id = target_id
	OR photo_id IN (SELECT id FROM media
		WHERE user_id = target_id);
	
	DELETE FROM media 
	WHERE user_id = target_id;

	DELETE FROM friend_requests
	WHERE initiator_user_id = target_id
	OR target_user_id = target_id;
	
	DELETE FROM users
	WHERE id = target_id;

	RETURN target_id;
END ^^
DELIMITER ;

SELECT delete_user(22) AS deleted_user;

/* Предыдущую задачу решить с помощью процедуры и 
 * обернуть используемые команды в транзакцию внутри процедуры. */

DROP PROCEDURE IF EXISTS remove_user;

DELIMITER ^^
CREATE PROCEDURE remove_user(target_id BIGINT UNSIGNED, OUT tran_result varchar(200))
BEGIN
	DECLARE `_rollback` BOOL DEFAULT 0;
	DECLARE code varchar(100);
	DECLARE error_string varchar(100);
	
	DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
	    BEGIN
	    	SET `_rollback` = 1;
			GET stacked DIAGNOSTICS CONDITION 1
	        code = RETURNED_SQLSTATE, error_string = MESSAGE_TEXT;
	    	set tran_result := concat('Error occured. Code: ', code, '. Text: ', error_string);
	    END;
	   
	START TRANSACTION;
		DELETE FROM messages 
		WHERE from_user_id = target_id 
		OR to_user_id = target_id;
	
		DELETE FROM likes 
		WHERE user_id = target_id 
		OR media_id IN (SELECT id FROM media 
			WHERE user_id = target_id);
	
		DELETE FROM users_communities
		WHERE user_id = target_id;
	
		DELETE FROM profiles
		WHERE user_id = target_id
		OR photo_id IN (SELECT id FROM media
			WHERE user_id = target_id);
		
		DELETE FROM media 
		WHERE user_id = target_id;
	
		DELETE FROM friend_requests
		WHERE initiator_user_id = target_id
		OR target_user_id = target_id;
		
		DELETE FROM users
		WHERE id = target_id;
		
		IF `_rollback` THEN ROLLBACK;
		ELSE 
			SET tran_result := 'ok';
			COMMIT;
		END IF;
END ^^
DELIMITER ;

CALL remove_user(11, @tran_result);
SELECT @tran_result;
