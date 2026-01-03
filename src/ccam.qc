 void () CCam;

          void () CCamChasePlayer = 
          {
             makevectors (self.v_angle);
             traceline ((self.origin + self.view_ofs),((((self.origin + self.view_ofs) + (v_forward * self.camview_z)) + (v_up * self.camview_x)) + (v_right * self.camview_y)),FALSE,self);
             setorigin (self.trigger_field,trace_endpos);
             WriteByte (MSG_ONE,5);
             WriteEntity (MSG_ONE,self.trigger_field);
             self.weaponmodel = "";
          };

          void () CCam = 
          {
             local entity camera;
             local entity spot;

             if (self.aflag == FALSE) 
             {
                self.aflag = TRUE;
                camera = spawn ();
                spot = spawn ();
                self.trigger_field = camera;
                camera.classname = "camera";
                camera.movetype = MOVETYPE_FLY;
                camera.solid = SOLID_NOT;
                setmodel (camera,"progs/eyes.mdl");
                setsize (camera,'0 0 0','0 0 0');
                makevectors (self.v_angle);
                traceline ((self.origin + self.view_ofs),(((self.origin + self.view_ofs) + (v_forward * -64.000))),FALSE,self);
                self.camview = '0 0 -64'; // added
                setorigin (camera,trace_endpos);
                camera.angles = self.angles;
                self.weaponmodel = "";
                msg_entity = self;
                WriteByte (MSG_ONE,5);
                WriteEntity (MSG_ONE,camera);
                WriteByte (MSG_ONE,10.000);
                WriteAngle (MSG_ONE,camera.angles_x);
                WriteAngle (MSG_ONE,camera.angles_y);
                WriteAngle (MSG_ONE,camera.angles_z);
                sprint (self,"Chase Cam On\n");
              }
              else
              {
                self.aflag = FALSE;
                msg_entity = self;
                WriteByte (MSG_ONE,5);
                WriteEntity (MSG_ONE,self);
                WriteByte (MSG_ONE,10);
                WriteAngle (MSG_ONE,self.angles_x);
                WriteAngle (MSG_ONE,self.angles_y);
                WriteAngle (MSG_ONE,self.angles_z);
                remove (self.trigger_field);
                sprint (self,"Chase Cam Off\n");
                W_SetCurrentAmmo ();
             }
          };

    void (float amount) CCamUp =
                                      {
                                              self.camview_x = self.camview_x + amount;
                                              if (self.camview_x < -16)
                                                      self.camview_x = -16;
                                              if (self.camview_x > 16)
                                                      self.camview_x = 16;
                                      };
                                      void (float amount) CCamRight =
                                      {
                                              local string aa;
                                              self.camview_y = self.camview_y + amount;
                                              if (self.camview_y < -8)
                                                      self.camview_y = -8;
                                              if (self.camview_y > 8)
                                                      self.camview_y = 8;
                                      };
                                      void (float amount) CCamForward =
                                      {
                                              self.camview_z = self.camview_z + amount;
                                              if (self.camview_z > -48)
                                                      self.camview_z = -48;
                                              if (self.camview_z < -72)
                                                      self.camview_z = -72;
                                      };

