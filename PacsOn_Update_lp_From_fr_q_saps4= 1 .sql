SELECT ftgnr, child.*
FROM fr AS child
WHERE ISNULL(child.q_saps4, 0) <> 1
  AND child.ftgnr LIKE '%-%'
  AND child.foretagkod = 9100
  AND EXISTS (
      SELECT 1
      FROM fr AS parent
      WHERE parent.q_saps4 = 1
        AND parent.foretagkod = child.foretagkod
        AND parent.ftgnr = LEFT(child.ftgnr, CHARINDEX('-', child.ftgnr) - 1)
  );

  begin tran
  UPDATE child
SET child.q_saps4 = 1
FROM fr AS child
WHERE ISNULL(child.q_saps4, 0) <> 1
  AND child.ftgnr LIKE '%-%'
  AND child.foretagkod = 9100
  AND EXISTS (
      SELECT 1
      FROM fr AS parent
      WHERE parent.q_saps4 = 1
        AND parent.foretagkod = child.foretagkod
        AND parent.ftgnr = LEFT(child.ftgnr, CHARINDEX('-', child.ftgnr) - 1)
  );
  commit tran 