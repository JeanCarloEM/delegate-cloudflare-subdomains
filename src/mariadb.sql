DELIMITER $$

/**
 *
 */
CREATE TABLE `users`{  
  uuid SERIAL,
  
  email varchar(255) NOT NULL PRIMARY KEY  ,
  
  created timestamp DEFAULT NULL,
  updated timestamp DEFAULT NULL,
}

CREATE TRIGGER usuers_before_insert BEFORE INSERT ON `users`
FOR EACH ROW 
BEGIN
  NEW.created = CURRENT_TIMESTAMP()
  NEW.updated = NULL; 
END;

CREATE TRIGGER usuers_before_update BEFORE UPDATE ON `users`
FOR EACH ROW 
BEGIN
  NEW.email = OLD.email;
  
  NEW.created = OLD.created
  NEW.updated = CURRENT_TIMESTAMP();
END;



/**
 *
 */
CREATE TABLE authentications{
  vmid SERIAL,
  
  auid BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  token varchar(64) NOT NULL,
  confirmed timestamp DEFAULT NULL,
    
  created timestamp DEFAULT NULL,
  updated timestamp DEFAULT NULL,  
  
  FOREIGN KEY (auid) REFERENCES users(uuid)
}

CREATE TRIGGER authentications_before_insert BEFORE INSERT ON `authentications`
FOR EACH ROW 
BEGIN
  NEW.confirmed = NULL; 

  NEW.created = CURRENT_TIMESTAMP()
  NEW.updated = NULL;   
END;

CREATE TRIGGER authentications_before_update BEFORE UPDATE ON `authentications`
FOR EACH ROW 
BEGIN
  NEW.auid = OLD.auid;
  NEW.token = OLD.token;
  
  NEW.created = OLD.created
  NEW.updated = CURRENT_TIMESTAMP();
  
  IF (OLD.confirmed <> NULL) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The `confirmed` column is read-only and has already been populated.';
    ROLLBACK;  
  END IF
  
  IF (NEW.confirmed <> NULL) THEN
    NEW.confirmed = CURRENT_TIMESTAMP();
  END IF
END;



/**
 *
 */
CREATE TABLE donations{  
  did SERIAL,
  
  duid BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  
  amount NUMBER NOT NULL,  
  payment_order varchar(255) DEFAULT NULL,
  payment_confirmation_data varchar(255) DEFAULT NULL,
  payment_confirmation timestamp DEFAULT NULL,
  
  created timestamp DEFAULT NULL,
  updated timestamp DEFAULT NULL,  
  
  FOREIGN KEY (duid) REFERENCES users(uuid)
}

CREATE TRIGGER records_before_insert BEFORE INSERT ON `donations`
FOR EACH ROW 
BEGIN
  NEW.created = CURRENT_TIMESTAMP()
  NEW.updated = NULL;   
  
  NEW.payment_confirmation = NULL;   
END;

CREATE TRIGGER records_before_update BEFORE UPDATE ON `donations`
FOR EACH ROW 
BEGIN
  NEW.duid = OLD.duid;
  NEW.amount = OLD.amount;
  NEW.payment_confirmation = NULL;   
  
  IF ((NEW.payment_order <> NULL) AND (NEW.payment_confirmation_data <> NULL)) THEN
    NEW.payment_confirmation = CURRENT_TIMESTAMP();
  END IF
  
  NEW.created = OLD.created
  NEW.updated = CURRENT_TIMESTAMP();  
END;


/**
 *
 */
CREATE TABLE zones{  
  zid SERIAL,  
  
  zone_name varchar(64) NOT NULL,
  cloudflare_zone_id varchar(255) NOT NULL,
  
  created timestamp DEFAULT NULL,
  updated timestamp DEFAULT NULL,    
}

CREATE TRIGGER records_before_insert BEFORE INSERT ON `zones`
FOR EACH ROW 
BEGIN
  NEW.created = CURRENT_TIMESTAMP()
  NEW.updated = NULL;
END;

CREATE TRIGGER records_before_update BEFORE UPDATE ON `zones`
FOR EACH ROW 
BEGIN
  NEW.zone_name = OLD.zone_name;
  NEW.cloudflare_zone_id = OLD.cloudflare_zone_id;
  
  NEW.created = OLD.created
  NEW.updated = CURRENT_TIMESTAMP();  
END;


/**
 * // 2024040440004657303
 */
CREATE TABLE records{
  rid SERIAL,
      
  zid BIGINT UNSIGNED NOT NULL
  validation BIGINT UNSIGNED NOT NULL,
  reciprocity BIGINT UNSIGNED DEFAULT NULL,    

  subdomain varchar(64) NOT NULL,   
  ns_hostname varchar(255) NOT NULL,    
  expires timestamp DEFAULT 0,  
  
  cloudflare_record_id: bigint unsigned DEFAULT NULL,    
  cloudflare_status enum('pending','registered','removed') DEFAULT 'pending',
     
  cl_registered timestamp DEFAULT NULL,
  cl_removed timestamp DEFAULT NULL,
  
  created timestamp DEFAULT NULL,
  updated timestamp DEFAULT NULL,    
  
  FOREIGN KEY (validation) REFERENCES authentications(vmid)
  FOREIGN KEY (reciprocity) REFERENCES donations(did)
  FOREIGN KEY (zid) REFERENCES zones(zid)    
}

CREATE TRIGGER records_before_insert BEFORE INSERT ON `records`
FOR EACH ROW 
BEGIN
  NEW.created = CURRENT_TIMESTAMP()
  NEW.updated = NULL;   
  NEW.deleted = NULL;   
  
  NEW.cl_registered = NULL;   
  NEW.cl_removed = NULL;    
  
  NEW.cloudflare_record_id = NULL;   
  NEW.cloudflare_status = 'pending';   
  
END;

CREATE TRIGGER records_before_update BEFORE UPDATE ON `records`
FOR EACH ROW 
BEGIN
  NEW.validation = OLD.validation;
  NEW.reciprocity = OLD.reciprocity;
  NEW.subdomain = OLD.subdomain;
  NEW.zid = OLD.zid; 
  
  NEW.cl_registered = OLD.cl_registered;
  NEW.cl_removed = OLD.cl_removed;
  
  IF (NEW.cloudflare_record_id <> OLD.cloudflare_record_id) AND (OLD.cloudflare_record_id <> NULL)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cloudflare registration ID cannot be changed once configured for the first time.';
    ROLLBACK;          
  END IF
  
  IF (NEW.cloudflare_status <> OLD.cloudflare_status) THEN
    IF (NEW.cloudflare_status == "registered") THEN
      IF (OLD.cl_registered <> NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Changed cloudflare status to "registered" but it was already registered.';
        ROLLBACK;        
      END IF;
    
      NEW.cl_registered = CURRENT_TIMESTAMP();
    ELSE IF (NEW.cloudflare_status == "removed") THEN
      IF (OLD.cl_removed <> NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Changed cloudflare status to "removed" but it was already removed.';
        ROLLBACK;        
      END IF;    
    
      NEW.cl_removed = CURRENT_TIMESTAMP();
    END IF;
  END IF;
  
  NEW.created = OLD.created  
  NEW.updated = CURRENT_TIMESTAMP();  
END;

END $$ DELIMITER ;
