// "Canonical|alias|alias..." — aliases are matched case-insensitively as whole tokens.
const RAW = `
Flutter|flutter
Dart|dart
Firebase|firebase|firestore
REST APIs|rest api|rest apis|restful|restful api|restful apis
GraphQL|graphql
State Management|state management|bloc|riverpod|provider|getx|redux|mobx
Unit Testing|unit testing|unit tests|unit test|jest|mocha|junit|pytest|flutter test|widget testing
CI/CD|ci/cd|ci cd|github actions|jenkins|gitlab ci|circleci|continuous integration
Git|git|github|gitlab|bitbucket
Docker|docker|containerization
Kubernetes|kubernetes|k8s
AWS|aws|amazon web services
Azure|azure
Google Cloud|gcp|google cloud
Linux|linux|ubuntu
JavaScript|javascript|js|ecmascript
TypeScript|typescript
Node.js|node.js|nodejs|node
Express|express.js|expressjs|express
React|react|react.js|reactjs
React Native|react native
Angular|angular
Vue.js|vue|vue.js|vuejs
Next.js|next.js|nextjs
HTML|html|html5
CSS|css|css3|sass|scss
Tailwind CSS|tailwind|tailwindcss
Python|python
Django|django
Flask|flask
FastAPI|fastapi
Java|java
Kotlin|kotlin
Swift|swift
SwiftUI|swiftui
Android|android|android studio
iOS|ios|xcode
C|c programming
C++|c++
C#|c#
.NET|.net|dotnet|asp.net
PHP|php
Laravel|laravel
Ruby on Rails|rails|ruby on rails
Ruby|ruby
Go|golang
Rust|rust
SQL|sql|t-sql|pl/sql
PostgreSQL|postgresql|postgres
MySQL|mysql
MongoDB|mongodb|mongo
Redis|redis
Supabase|supabase
Machine Learning|machine learning|ml
Deep Learning|deep learning
TensorFlow|tensorflow
PyTorch|pytorch
Pandas|pandas
NumPy|numpy
Data Analysis|data analysis|data analytics
Power BI|power bi|powerbi
Tableau|tableau
Excel|excel|microsoft excel
Figma|figma
UI/UX Design|ui/ux|ui ux|ux design|ui design
Agile|agile
Scrum|scrum
Jira|jira
Microservices|microservices
System Design|system design
Data Structures|data structures|algorithms|dsa
OOP|oop|object-oriented|object oriented
Communication|communication skills
Teamwork|teamwork|team player|collaboration
Problem Solving|problem solving|problem-solving
Leadership|leadership
Project Management|project management
Cybersecurity|cybersecurity|cyber security|penetration testing
Selenium|selenium
Postman|postman
Networking|computer networking|tcp/ip
`;

const ENTRIES = RAW.trim().split('\n').map((l) => {
  const [name, ...aliases] = l.split('|');
  return { name, aliases: [...new Set([name.toLowerCase(), ...aliases])] };
});

const esc = (s) => s.replace(/[.*+?^${}()|[\]\\/]/g, '\\$&');

const MATCHERS = ENTRIES.map((e) => ({
  name: e.name,
  // Not preceded/followed by letters, digits, +, # — so "java" won't hit "javascript"
  regex: new RegExp(`(?<![a-z0-9+#.])(?:${e.aliases.map(esc).join('|')})(?![a-z0-9+#])`, 'i'),
}));

/** Every dictionary skill found in `text`. */
function findSkills(text) {
  return MATCHERS.filter((m) => m.regex.test(text)).map((m) => m.name);
}

/** Map free-text skill names (from job posts) to canonical names when known. */
const LOOKUP = new Map();
for (const e of ENTRIES) for (const a of e.aliases) LOOKUP.set(a.toLowerCase(), e.name);
function canonical(name) {
  const n = String(name || '').trim();
  return LOOKUP.get(n.toLowerCase()) || n;
}

module.exports = { findSkills, canonical };
