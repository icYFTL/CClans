--   [SQLite3 object]
--      Promt: Always starts with lowercase symbol
--      Example var name: user
--      Description: Object with clanID, memberUUID, role properties
--
--   [cPlayer object]
--      Promt: Always starts with uppercase symbol
--      Example var name: User
--      Description: Built-in object
--
--   [Unknow pokemon]
--      Promt: Always starts with underscore symbols
--      Example var name: _user
--      Description: Temp or some kind a useless.

function clanHandler(Cmd, User)
  if Cmd[1] == '/clan' then
    if Cmd[2] then
      if Cmd[2] == 'register' then
        addClan(Cmd[3], User);
      elseif Cmd[2] == 'leave' then
        leaveFromClan(User);
      elseif Cmd[2] == 'destruct' then
        destructClan(User);
      elseif Cmd[2] == 'invite' then
        sendInviteToUser(User, Cmd[3]);
      elseif Cmd[2] == 'delegate' then
        delegateClan(User, Cmd[3]);
      elseif Cmd[2] == 'accept' then
        acceptInvitation(User, Cmd[3]);
      elseif Cmd[2] == 'exclude' then
        excludeFromClan(User, Cmd[3]);
      elseif Cmd[2] == 'help' then
        helpClan(User, Cmd[3]);
      elseif Cmd[2] == 'setbase' then
        addClanBase(User);
      elseif Cmd[2] == 'base' then
        tpClanBase(User);
      elseif Cmd[2] == 'delbase' then
        removeClanBase(User);
      elseif Cmd[2] == 'wish' then
        sendWishToClan(User, Cmd[3]);
      elseif Cmd[2] == 'willing' and Cmd[3] == 'clear' then
        clearAllWishes(User);
      elseif Cmd[2] == 'willing' then
        acceptWish(User, Cmd[3]);
      end
    else
      clanInfo(User);
    end
  end
  return true;
end

function delegateClan(User, Slayer)
  if not User:HasPermission("cclans.delegate") then
      User:SendMessageFailure('You don\'t have permissions to do that.');
      return true;
  end

  if not Slayer then
    User:SendMessageFailure('Specify player\'s name like /clan delegate <NAME>');
    return true;
  end

  local user = getUser(User);
  local clan = getClan(nil, user.clanID);
  done = false;
  if user.role ~= 'owner' then
      User:SendMessageFailure('You don\'t have permissions to do that.');
      return true;
  end
  cRoot:Get():FindAndDoWithPlayer(Slayer,
  function(slayer)
        if isMemberOf(slayer, clan) then
            local _slayer = getUser(slayer);
            if _slayer.memberUUID == user.memberUUID then
              User:SendMessageFailure('You can\'t delegate clan to yourself.')
              done = true;
              return true;
            end

            delegateClanDB(clan, _slayer);
            User:SendMessageSuccess('You delegated clan to ' .. Slayer .. '\nNow you\'re member of the clan.');
            clanBroadcast(clan, 'Now '.. Slayer .. ' owner of the clan.');
            done = true;
            return true;
        else
            User:SendMessageFailure(Slayer .. ' is not member of the clan');
            done = true;
            return true;
        end
  end
  );
  if not done then
    User:SendMessageFailure('Invalid player.');
  end
end

function destructClan(User)
  if not User:HasPermission("cclans.destruct") then
      User:SendMessageFailure('You don\'t have permissions to do that.');
      return true;
  end

  if not isUserInClan(User) then
    User:SendMessageFailure('You\'re not in the clan now.');
    return true;
  end

  local user = getUser(User);
  local clan = getClan(nil, user.clanID);
  if user.role == 'owner' then
      clanBroadcast(clan, 'Clan destructed. Now, yor\'re clanless.');
      removeClanDB(clan);
      User:SendMessageSuccess('Successfully destructed.')
  else
      User:SendMessageFailure('You don\'t have permissions to do that.');
  end
  return true;
end

function leaveFromClan(User)
  if not User:HasPermission("cclans.leave") then
      User:SendMessageFailure('You don\'t have permissions to do that.');
      return true;
  end

  if not isUserInClan(User) then
    User:SendMessageFailure('You are not in clan now.');
    return true;
  end

  local user = getUser(User);
  if user.role == 'owner' then
    User:SendMessageFailure('You can\'t leave as owner.\nDelegate your clan to somebody /clan delegate <PLAYER>\nOr destruct your clan /clan destruct');
    return true;
  end

  removeFromClanDB(user);
  User:SendMessageSuccess('You have left the clan.');
  clanBroadcast(getClan(nil, user.clanID), User:GetName() .. ' has left the clan.');
  return true;
end

function sendInviteToUser(User, Slayer)
  if not User:HasPermission("cclans.sendInviteUser") then
      User:SendMessageFailure('You don\'t have permissions to do that.');
      return true;
  end

  local user = getUser(User);

  if user.role ~= 'owner' and user.role ~= 'moderator' then
    User:SendMessageFailure('You don\'t have permissions to do that.');
      return true;
  end

  if not Slayer then
    User:SendMessageFailure('Specify player to send invite like /clan invite <NAME>');
    return true;
  end
  done = false --idk how to check invalid name

  cRoot:Get():FindAndDoWithPlayer(Slayer, function(slayer)
        local _slayer = getUser(slayer);
        if user.memberUUID == _slayer.memberUUID then
          User:SendMessageFailure('You can\'t invite yourself.');
          done = true;
          return true;
        end

        if _slayer then
          if isUserInClan(slayer) then
            User:SendMessageFailure('Player already in clan.');
            done = true;
            return true;
          end
        end
        if #getInvites(User) > 4 then
          User:SendMessageFailure(Slayer .. ' already have 5 invitations from other clans');
          done = true;
          return true;
        end

        if isInviteExists(slayer, User) then
          User:SendMessageFailure('You already invite him.');
          done = true;
          return true;
        end

        addInvite(User, slayer);

        slayer:SendMessageInfo('You have invited to clan ' .. getClan(nil, user.clanID).name .. ' by ' .. User:GetName() .. '\nUse /clan accept to accept the invintation');
        User:SendMessageSuccess('Invintation sent.');
        done = true;
        return true;
  end
  );
  if not done then
    User:SendMessageFailure('Invalid player.')
  end
  return true;
end

function acceptInvitation(User, Number)
  if not User:HasPermission("cclans.acceptInvite") then
      User:SendMessageFailure('You don\'t have permissions to do that.');
      return true;
  end

  if isUserInClan(User) then
    User:SendMessageFailure('You can\'t accept the invitation because you\'re already in clan.');
    return true;
  end

  local invites = getInvites(User);
  local _slayer = nil;

  if #invites < 1 then
    User:SendMessageFailure('There\'re no any invites.')
    return true;
  elseif not Number then
    local msg = 'Choose invite to accept:\n'
    for i, val in ipairs(invites) do
      cRoot:Get():DoWithPlayerByUUID(val, function(slayer)
        _slayer = getUser(slayer);
        local clan = getClan(nil, _slayer.clanID);
        msg = msg .. tostring(i) .. '. ' .. clan.name .. '\n';
      end
      );
    end
    msg = msg .. 'Usage: /clan accept <NUMBER OF INVINTATION>'
    User:SendMessageInfo(msg);
    return true;
  elseif Number then
    local joined = false;
    for i, val in ipairs(invites) do -- IDK invites[Number] looks like doesn't work.
      if i == tonumber(Number) then
        _slayer = val;
        cRoot:Get():DoWithPlayerByUUID(val,
        function(slayer)
            local _slayer = getUser(slayer);
            local clan = getClan(nil, _slayer.clanID);
            addUserToClan(User, clan);
            User:SendMessageSuccess('Successfully joined.');
            joined = true;
        end);
      end
    if not joined then
    User:SendMessageFailure('Invalid clan number');
    end
  end
    cRoot:Get():DoWithPlayerByUUID(_slayer, function(slayer)
        slayer:SendMessageInfo(User:GetName() .. ' joined your clan using your invitation');
        delInvite(slayer, User);

        -- local cUsers = getClanUsers(getClan(nil, getUser(User).clanID));
        -- for i,v in ipairs(cUsers) do
        --   print(i, v)
        --   if val.role == 'owner' then
        --   cRoot:Get():FindAndDoWithPlayer(cUser.memberUUID,
        --   function(cUser)
        --       cUser:SendMessageInfo(slayer .. ' invited ' .. User:GetName() .. ' to your clan and ' .. User:GetName() .. ' accepted it.');
        --       return true;
        --   end
        --   );
        --   end

        return true;
      -- end
    end
    );
  end
end

function sendWishToClan(User, Clan)
  if not User:HasPermission("cclans.sendJoinClan") then
      User:SendMessageFailure('You don\'t have permissions to do that.');
      return true;
  end

  if isUserInClan(User) then
    User:SendMessageFailure('You can\'t send the wish because you\'re already in clan.');
    return true;
  end

  if not Clan then
    User:SendMessageFailure('Specify clan name.\nUsage /clan wish <CLAN_NAME>');
    return true;
  end

  clan = getClan(Clan, nil);
  if not clan then
    User:SendMessageFailure('Invalid clan.');
    return true;
  end

  if #getWishes(clan) > 10 then
    User:SendMessageFailure('Clan has wishes limit. Try again later or choose another clan.');
    return true;
  end

  if isWishExists(User, clan) then
    User:SendMessageFailure('You already sent the wish to this clan.');
    return true;
  end

  User:SendMessageInfo('The wish has been sent.');
  clanStaffBroadcast(clan, User:GetName() .. ' wanna join your clan. Use /clan wishes');
  addWish(User, clan);

  return true;
end

function acceptWish (User, Number)
  if not User:HasPermission("cclans.acceptWish") then
      User:SendMessageFailure('You don\'t have permissions to do that.');
      return true;
  end

  if not isUserInClan(User) then
    User:SendMessageFailure('You can\'t accept the wish because you\'re not in a clan.');
    return true;
  end


  local user = getUser(User);

  if user.role ~= 'owner' and user.role ~= 'moderator' then
    User:SendMessageFailure('You don\'t have permissions to do that.');
      return true;
  end

  local clan = getClan(nil, user.clanID);
  local slayer = nil;

  local wishes = getWishes(clan);

  if #wishes < 1 then
    User:SendMessageFailure('There\'re no any wishes.')
    return true;
  elseif not Number then
    local msg = 'Choose wish to accept:\n'
    for i, val in ipairs(wishes) do
      cRoot:Get():DoWithPlayerByUUID(val,
      function(slayer)
        msg = msg .. tostring(i) .. '. ' .. slayer:GetName() .. '\n';
      end
      );
    end
    msg = msg .. 'Usage: /clan willing <NUMBER OF INVINTATION>'
    User:SendMessageInfo(msg);
    return true;
  elseif Number then
    local joined = false;
    for i, val in ipairs(wishes) do -- IDK invites[Number] looks like doesn't work.
      if i == tonumber(Number) then
        cRoot:Get():DoWithPlayerByUUID(val,
        function(slayer)
            local _slayer = getUser(slayer);
            local clan = getClan(nil, user.clanID);
            addUserToClan(slayer, clan);
            slayer:SendMessageSuccess('You have been joined to ' .. clan.name);
            removeAllWishesFromUser(slayer);
            User:SendMessageSuccess(slayer:GetName() .. ' successfully joined.');
            clanBroadcast(clan, slayer:GetName() .. ' was joined to the clan.');
            joined = true;
        end);
      end
    end
    if not joined then
      User:SendMessageFailure('Invalid wish number');
    end
  end
end

function clearAllWishes (User)
  if not User:HasPermission("cclans.clearWishes") then
      User:SendMessageFailure('You don\'t have permissions to do that.');
      return true;
  end

  if not isUserInClan(User) then
    User:SendMessageFailure('You can\'t clear the wishes because you\'re not in a clan.');
    return true;
  end

  local user = getUser(User);

  if user.role ~= 'owner' and user.role ~= 'moderator' then
    User:SendMessageFailure('You don\'t have permissions to do that.');
      return true;
  end

  local clan = getClan(nil, user.clanID);

  clearWishes(clan);

  User:SendMessageSuccess('All wishes has been removed.');
  return true;
end

function excludeFromClan(User, Slayer)
    if not User:HasPermission("cclans.excludeFromClan") then
      User:SendMessageFailure('You don\'t have permissions to do that.');
      return true;
  end

  if not isUserInClan(User) then
    User:SendMessageFailure('You are not in clan now.');
    return true;
  end

  local user = getUser(User);
  local clan = getClan(nil, user.clanID);

  if user.role ~= 'owner' and user.role ~= 'moderator' then
    User:SendMessageFailure('You don\'t have permissions to do that.');
    return true;
  end

  if not Slayer then
    User:SendMessageFailure('Specify player\'s name like /clan exclude <NAME>');
    return true;
  end

  done = false;
  cRoot:Get():FindAndDoWithPlayer(Slayer,
  function(slayer)
    if slayer:GetUUID() == User:GetUUID() then
      User:SendMessageFailure('You can\'t exclude yourself.\nUse /clan leave or /clan destruct .');
      done = true;
      return true;
    end
    removeFromClanDB(getUser(slayer));

    slayer:SendMessageInfo('You have been excluded from clan by ' .. User:GetName());
    User:SendMessageSuccess(Slayer .. ' has been excluded by you.');
  end);

  if not done then
    User:SendMessageFailure('Invalid player.');
  end
end

function clanInfo(User)
  msg = 'CClan plugin v' .. g_PluginInfo.Version .. '\n';
  msg = msg .. 'My clan: '

  if isUserInClan(User) then
    msg = msg .. getClan(nil, getUser(User).clanID).name .. '\n';
  else
    msg = msg .. 'clanless\n';
  end

  if isUserInClan(User) then
    local clan = getClan(nil, getUser(User).clanID);
    msg = msg .. 'Total clanmates: ' .. tostring(#getClanUsers(clan)) .. '\n';
    msg = msg .. 'Rating: <NON IMPLEMENTED YET>\n'; -- TODO: RATING
    for i, user in ipairs(getClanUsers(clan)) do
      if user.role == 'owner' then
        cRoot:Get():DoWithPlayerByUUID(user.memberUUID,
        function (_user)
          msg = msg .. 'Owner: ' .. _user:GetName() .. '\n';
          return true;
        end);
    end
    msg = msg .. 'My role: ' .. getUser(User).role .. '\n';
  end
  end

  msg = msg .. 'Use /clan help for additional info.';
  User:SendMessageInfo(msg);
  return true;
end

function addClan(Name, User)
    if not User:HasPermission("cclans.addClan") then
        User:SendMessageFailure('You don\'t have permissions to do that.');
        return true;
    end

    if not Name then
      User:SendMessageFailure('Empty clan name.\nUsage: /clan register <NAME>');
      return true;
    end

    if #Name < 3 or #Name > 20 then
      User:SendMessageFailure('Invalid clan name.\nClan name\'s length must be 3>= (NAME) <= 15');
      return true;
    end

    if not checkCName(Name) then
      User:SendMessageFailure('Invalid clan name.\nClan name must consists of alphanumeric symbols [A-Za-z0-9]');
      return true;
    end

    if isClanExists(Name) then
      User:SendMessageFailure('Clan with this name already exists.');
      return true;
    end

    if isUserInClan(User) then
      User:SendMessageFailure('You are already in clan.\nLeave first.');
      return true;
    end

    addClanDB(Name, User);
    User:SendMessageSuccess("Successfully registered.");

  end

function helpClan(User, Page)
  local totalPages = 3;

  if not Page then
    Page = "1";
  end

  if Page == "1" then
    msg =        '\n/clan - Show status\n';
    msg = msg .. '/clan register - Register a clan\n';
    msg = msg .. '/clan leave - Leave the clan\n';
    msg = msg .. '/clan destruct - Destruct a clan\n';
    msg = msg .. '/clan invite - Invite a player to the clan\n';
  elseif Page == "2" then
    msg = '\n/clan delegate - Delegate the clan to a player\n';
    msg = msg .. '/clan accept - Accept the invintation to the clan\n';
    msg = msg .. '/clan exclude - Exclude a player from the clan\n';
    msg = msg .. '/clan setbase - Set clan base\n';
    msg = msg .. '/clan base - Teleport to clan base\n';
    msg = msg .. '/clan delbase - Delete clan base\n';
  elseif Page == "3" then
    msg = msg .. '\n/clan wish - Send wish about joining to the clan\n';
    msg = msg .. '\n/clan willing - Accept the wish from player\n';
    msg = msg .. '\n/clan willing clear - Clear all wishes\n';
    msg = msg .. '\n/clan help - Show clan help page\n';
  else
    User:SendMessageFailure('Invalid page. There\'re ' .. tostring(totalPages) .. ' pages in help.')
    return true;
  end

  msg = msg .. 'Page ' .. Page .. ' of ' .. tostring(totalPages);
  User:SendMessageInfo(msg);
  return true;
end

function addClanBase(User)
  if not User:HasPermission("cclans.addClanBase") then
      User:SendMessageFailure('You don\'t have permissions to do that.');
      return true;
  end

  if not isUserInClan(User) then
    User:SendMessageFailure('You are not in clan now.');
    return true;
  end

  local user = getUser(User);

  if user.role ~= 'owner' then
    User:SendMessageFailure('You don\'t have permissions to do that.');
    return true;
  end

  local position = User:GetPosition();
  local clan = getClan(nil, getUser(User).clanID);

  addClanPos(clan, position);

  clanBroadcast(clan, User:GetName() .. ' set new clan base at [X:' .. tostring(position.x) .. ' Y:' .. tostring(position.y) .. ' Z:' .. tostring(position.z) .. ']');
  return true;
end

function removeClanBase(User)
  if not User:HasPermission("cclans.removeClanBase") then
      User:SendMessageFailure('You don\'t have permissions to do that.');
      return true;
  end

  if not isUserInClan(User) then
    User:SendMessageFailure('You are not in clan now.');
    return true;
  end

  local user = getUser(User);

  if user.role ~= 'owner' then
    User:SendMessageFailure('You don\'t have permissions to do that.');
    return true;
  end

  local clan = getClan(nil, getUser(User).clanID);

  removeClanPos(clan);
  clanBroadcast(clan, User:GetName() .. ' removed clan base.');

  return true;
end

function tpClanBase(User)
  if not User:HasPermission("cclans.tpClanBase") then
      User:SendMessageFailure('You don\'t have permissions to do that.');
      return true;
  end

  if not isUserInClan(User) then
    User:SendMessageFailure('You are not in clan now.');
    return true;
  end

  local clan = getClan(nil, getUser(User).clanID);
  local base = getClanPos(clan);

  if not base.baseX or not base.baseY or not base.baseZ then
    User:SendMessageFailure('Clan doesn\'t have the base.');
    return true;
  end
  -- User:SetPosX(0);
  -- User:SetPosY(0);
  -- User:SetPosZ(0); idk why
  User:TeleportToCoords(base.baseX, base.baseY, base.baseZ);
  User:SendMessageSuccess('Now you are in the clan base.');
  return true;
end
