-- Optional sample jobs.
WITH j AS (
  INSERT INTO public."JobPost"(title, company, location, description) VALUES
   ('Mobile App Developer','Nova Tech','Dhaka, BD','Build cross-platform mobile apps.'),
   ('Flutter Engineer','Brightside Labs','Remote','Own Flutter features end to end.'),
   ('Junior Software Engineer','Orbit Systems','Dhaka, BD','Join our product engineering team.'),
   ('Backend Developer','Cloudora','Dhaka, BD','Design REST APIs and data models.')
  RETURNING id, title)
INSERT INTO public."JobSkill"("jobId", skillname, "isRequired")
SELECT j.id, s.skill, s.req FROM j JOIN (VALUES
 ('Mobile App Developer','Flutter',true),('Mobile App Developer','Dart',true),('Mobile App Developer','REST APIs',true),
 ('Mobile App Developer','Firebase',false),('Mobile App Developer','Git',true),('Mobile App Developer','CI/CD',false),
 ('Flutter Engineer','Flutter',true),('Flutter Engineer','Dart',true),('Flutter Engineer','State Management',true),
 ('Flutter Engineer','Unit Testing',true),('Flutter Engineer','CI/CD',false),
 ('Junior Software Engineer','Git',true),('Junior Software Engineer','SQL',true),('Junior Software Engineer','JavaScript',true),
 ('Junior Software Engineer','Unit Testing',false),
 ('Backend Developer','Node.js',true),('Backend Developer','Express',true),('Backend Developer','PostgreSQL',true),
 ('Backend Developer','REST APIs',true),('Backend Developer','Docker',false)
) AS s(title, skill, req) ON s.title = j.title;
