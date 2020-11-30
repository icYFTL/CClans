local DB = nil;

function initDB ()
  DB = sqlite3.open('clans.sqlite3');
  DB:exec('CREATE TABLE IF NOT EXISTS clans (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL unique, baseX REAL, baseY REAL, baseZ REAL);');
  DB:exec('CREATE TABLE IF NOT EXISTS members (clanID INTEGER NOT NULL, memberUUID TEXT NOT NULL, role TEXT NOT NULL DEFAULT "member");');
  return true;
end

function getClan(Name, ID)
  if Name then
    for row in DB:nrows(string.format('SELECT * FROM clans WHERE name="%s";', Name)) do
        return row;
    end
  end

  if ID then
    for row in DB:nrows(string.format('SELECT * FROM clans WHERE id=%i;', ID)) do
        return row;
    end
  end

  return {};
end

function getUser(User)
  for row in DB:nrows(string.format('SELECT * FROM members WHERE memberUUID="%s";', User:GetUUID())) do
      return row;
  end
  return {};
end

function getClanPos(Clan)
  res = {}
  for row in DB:nrows(string.format('SELECT baseX,baseY,baseZ FROM clans WHERE id=%i;', Clan.id)) do res=row; end
  return res;
end

function getClanUsers(Clan)
    res = {}
    for row in DB:nrows(string.format('SELECT * FROM members WHERE clanID=%i;', Clan.id)) do table.insert(res, row); end
    return res;
end

function getClans()
  res = {}
  for row in DB:nrows(string.format('SELECT * FROM clans;')) do table.insert(res, row); end
  return res;
end

function delegateClanDB(Clan, User)
  DB:exec(string.format('UPDATE members SET role="member" WHERE clanID=%i AND role="owner";', Clan.id));
  DB:exec(string.format('UPDATE members SET role="owner" WHERE clanID=%i AND memberUUID="%s";', Clan.id, User.memberUUID));
  return true;
end

function addClanDB(Name, User)
  DB:exec(string.format('INSERT INTO clans (name) VALUES ("%s");', Name));
  id = tonumber(getClan(Name, nil).id);
  DB:exec(string.format('INSERT INTO members (clanID, memberUUID, role) VALUES (%i, "%s", "%s");', id, User:GetUUID(), "owner"));
  return true;
end

function addUserToClan(User, Clan)
  DB:exec(string.format('INSERT INTO members (clanID, memberUUID, role) VALUES (%i, "%s", "%s");', Clan.id, User:GetUUID(), "member"));
  return true;
end

function addClanPos(Clan, Obj)
  X = Obj.x;
  Y = Obj.y;
  Z = Obj.z;

  DB:exec(string.format('UPDATE clans SET baseX=%f, baseY=%f, baseZ=%f WHERE id=%i;', X, Y, Z, Clan.id));
  return true;
end

function removeClanPos(Clan)
  DB:exec(string.format('UPDATE clans SET baseX=NULL, baseY=NULL, baseZ=NULL WHERE id=%i;', Clan.id));
  return true;
end


function removeFromClanDB(User)
  DB:exec(string.format('DELETE FROM members WHERE clanID=%i AND memberUUID="%s"', User.clanID, User.memberUUID));
  return true;
end

function removeClanDB(Clan)
  DB:exec(string.format('DELETE FROM clans WHERE name="%s";', Clan.name));
  DB:exec(string.format('DELETE FROM members WHERE clanID=%i;', Clan.id))
  return true;
end


function isMemberOf(User, Clan)
  for user in DB:rows(string.format('SELECT memberUUID FROM members WHERE clanID=%i and memberUUID="%s";', Clan.id, User:GetUUID())) do
      return true;
  end
  return false;
end

function isClanExists(Name)
  for a in DB:rows(string.format('SELECT name FROM clans WHERE name="%s";', Name)) do return true; end
  return false;
end

function isUserInClan(User)
  for a in DB:rows(string.format('SELECT memberUUID FROM members WHERE memberUUID="%s"', User:GetUUID())) do return true; end
  return false;
end
