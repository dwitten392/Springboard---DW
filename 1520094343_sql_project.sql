/* Welcome to the SQL mini project. For this project, you will use
Springboard' online SQL platform, which you can log into through the
following link:

https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

Note that, if you need to, you can also download these tables locally.

In the mini project, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */



/* Q1: Some of the facilities charge a fee to members, but some do not.
Please list the names of the facilities that do. */

/* Squash Court, Tennis Court 1, Tennis Court 2, Massage Room 1, Massage Room 2 */

SELECT *
FROM Facilities
WHERE membercost >0

/* Q2: How many facilities do not charge a fee to members? */
/* 4 */

SELECT COUNT( membercost )
FROM Facilities
WHERE membercost =0

/* Q3: How can you produce a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost?
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT facid, name, membercost, monthlymaintenance
FROM Facilities
WHERE membercost >0
AND membercost < ( 0.2 * monthlymaintenance ) 

/* Q4: How can you retrieve the details of facilities with ID 1 and 5?
Write the query without using the OR operator. */

SELECT *
FROM Facilities
WHERE facid IN (1, 5)

/* Q5: How can you produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100? Return the name and monthly maintenance of the facilities
in question. */

SELECT name, monthlymaintenance,
CASE
	WHEN monthlymaintenance < 100 THEN "cheap"
	ELSE "expensive"
END AS 'category'
FROM Facilities

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Do not use the LIMIT clause for your solution. */

SELECT surname, firstname, joindate
FROM Members
WHERE joindate = (
SELECT MAX( joindate )
FROM Members ) 

/* Q7: How can you produce a list of all members who have used a tennis court?
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

select distinct
concat(m.firstname, ' ',  m.surname) as member,
f.name as facility

from
     Members m
	 inner join Bookings b on b.memid = m.memid
     inner join Facilities f on b.facid = f.facid
where
	 f.name = 'Tennis Court 2' or f.name = 'Tennis Court 1'
order by member


/* Q8: How can you produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30? Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

select f.name,
	case when m.firstname = 'GUEST' 
		then m.firstname
		else concat(m.firstname, ' ', m.surname)
	end as username,
case 
	when m.memid = 0 then b.slots * f.guestcost
	else b.slots * f.membercost
end as cost
from Members m
	inner join Bookings b on m.memid = b.memid
	inner join Facilities f on b.facid = f.facid
where 
b.starttime >= '2012-09-14' and b.starttime < '2012-09-15' and (
(m.memid = 0 and b.slots * f.guestcost >= 30 ) or 
(m.memid != 0 and b.slots * f.membercost >= 30) )
order by cost desc


/* Q9: This time, produce the same result as in Q8, but using a subquery. */

select * 
from (
	select f.name as facility, CONCAT(m.firstname,  ' ', m.surname ) as name, 
		case when b.memid =0
			THEN f.guestcost * b.slots
			ELSE f.membercost * b.slots
		end as cost
from Bookings b
inner join Facilities f on b.facid = f.facid
inner join Members m on b.memid = m.memid
where b.starttime >= '2012-09-14' and b.starttime < '2012-09-15'
)sub
WHERE sub.cost >30
ORDER BY sub.cost DESC



/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

select * 
from (
	select sub.facility, sum(sub.cost) as revenue
from (
	select f.name as facility, 
	case when b.memid =0
		then f.guestcost * b.slots
		else f.membercost * b.slots
	end as cost
from Bookings b
inner join Facilities f ON b.facid = f.facid
inner join Members m ON b.memid = m.memid
)sub
group by sub.facility
)sub2
where sub2.revenue <1000
