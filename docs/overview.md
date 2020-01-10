# Overview of Backend Architecture of a DHIS2 tracker implementation

## Introduction
The DHIS2 software has been developed over a long period of time - the earliest version 
was first deployed live in Kerala, India, around 2007.  Much has changed since then. 
Though it was a web-based application, most early versions were being deployed on Local 
Area Networks in health district offices.  With improved network connectivity of districts,
and later also of health facilities, it became increasingly viable to host DHIS2 in a central
national (or Indian state) server environment.  Countries like Kenya, Rwanda and Ghana led the 
early trend of hosting the national aggregate data routine reporting systems on the web. 

In retrospect, many of these early implementations look naive in the light of the present context.
It was quite a common practice to run DHIS2 directly off the tomcat servlet container with no
SSL/TLS encryption, no DNS setup and no frontend proxy.  Often there was no provison made for database
backups.  Ownership and governance of the system in terms of where it was hosted, who controlled the
account (when it was in the commercial cloud), who had backend access to the system etc were 
often overlooked in the haste to get the system rapidly established.  Unfortunately there are still
a number of these problems which persist in systems to be found today.  For the most part things have
got better, but there are new drivers to ensure that we do better still.  In particular:

1.  The surge of interest in DHIS2 Tracker, which enables the collection, storage and processing of
 identifiable data on rights-bearing subjects (humans), raises the bar in terms of what is acceptable security practice.
2.  The increasingly hostile nature of the internet as an environment for hosting resulting from a growing prevalence of criminal activity as well as hostile state and other actors.
3.  The growth in size of country systems require them to be better managed from a performance perspective as well a steadily increasing value of the data.

Each of these factors (and no doubt others) contribute to the need to develop, articulate and grow an improved practice in the field of hosting DHIS2 services.

What we try to do in this document is to provide some principles, together with an outline of a concrete
reference case, to guide implementers who are trying to do a more secure and robust setup.  Whereas the major emphasis here is on the backend, we acknowledge that this is just one (relatively small) aspect of a bigger picture concering governance at all levels.  

## Principles
The following are a high level list of principles which should inform any implementation:

### Top level
1.  An organisation that claims to take security seriously *must* have an explicit security plan or posture.  What principles are important?  What legislation/regulations apply? What processes and artefacts exist to manage security?  The high level plan should at least provide answers to these questions.  Various methodologies exist (eg ISO27002) to map those out into more concrete activities.
2. Whose job is it?  Is that person(s) sufficiently empowered and mandated to do the job? 
3.  "The cloud" and "the web" are just metaphors.  It is one thing for the general public, or even system
 users, to view it as something magically just there.  But system implementers (and planners and
 funders) have to pierce this fantasy  and appreciate the real consequences of the material and social
 reality of the system.  Questions like who and where become important, with real implications for cost, human capacity, physical environment etc..  
4. Human beings enjoy (to a lesser or greater extent) the recognition of certain rights, including in most constitutions the protection of privacy.  Failure to protect the privacy of subjects in the DHIS2 application can lead to very tangible actual harm as well as blackmail, harassment, identity theft etc.
As a system implementer you have the obligation to be able to demonstrate that adequate and appropriate 
provisons are being taken.  (1 and 2 above are generally the first steps in making such a demonstration)
5. Both individual and aggregate data related to health can be critical to the ongoing treatment of
patients as well as management of the system.  Data which is lost or altered can have bad consequences.
Implementers must also be able to demonstrate that adequate and appropriate provisions are taken to
protect the availability and integrity of data.  Again refer to 1 and 2 above.
6.  An increasing number of coutries have laws which aim to protect the data rights of citizens and others.  Not paying sufficient attention to the above can lead to implementers, engineers and others falling foul of the law.  Be aware of the legal regime and manage your exposure to risk.

### Application
To be completed - user role management, account management, sharing configuration, staging etc.
Also data sharing agreements, access to and from different systems etc.

### Backend systems
1.  All systems should be setup according to a **documented standard** (note that automation is the best
way to enforce this).
2.  All data should be **encrypted in transit** outside of the infrastructure directly under your control. This includes proper configuration of SSL/TLS on the DHIS2 web application as well as the transmission
of sensitive backup files like database dumps. The scope of what consists of *"infrastructure under your control"* might vary significantly with context. 
3.  All data should be **encrypted at rest**.  This generally implies that the database data directories
need to be on an encrypted filesystem.  Particular care needs to be taken to ensure that unencrypted database backup files do not end up on unencrypted file systems. 
4.  **Access** to the backend should be strictly controlled and audited.  This implies that backend 
technicians only access the infrastructure using personal identifying accounts and ssh keys (ie. no more
logging in as the *dhis* user).  External technical assistants should sign a non-disclosure agreement and
their accounts disabled after the task is complete.
5.  The DHIS2 application requires a **broad network infrastructure** platform to build upon.  Care
 should be taken to ensure that the network on which DHIS2 will run is correctly configured, secured
 and monitored.
6.  The DHIS2 application consists of a number of separate components.  Also it is likely to co-exist in
an environment with other health applications.  Security, performance and monitoring considerations 
dictate that these **components should be suitably isolated** from one another. Individual components should run within the scope of their own machine, virtual machine or container.
7.  There should be a documented (and regularly tested) **disaster recovery plan** consisting of an automated
backup schedule and specific recovery targets (How long can I afford to be offline?  How much data can
I afford to lose?).  For highly critical systems, such as transactional point of care, failsafe systems
incorporating redundancy might be required.  Be aware that reliability costs.

It is not always possible for an organisation to adhere to such a list of principles.  In that case there
are a number of possibilities to consider:
* reduce the exposure to risk by not collecting person identifiable data at all
* create a realistic costed plan to implement security management
* consider outsourcing those aspects of the system which you do not currently have the physical, organisational or technical resources to implement "in-house".  Dependending on external resources for 
infrastructure or even full application management can be a smart move.  But be aware that there are
other, different challenges to consider when outsourcing.

## The variety of context
### Material context

There is wide variety of material contexts we find in practice.  The following short list shows the most typical: 
1.  Hosting in the basement
2.  Own data centre
3.  Co-location of server(s) in local data centre
4.  National data centre
5.  International commercial cloud (VPS) service
6.  Managed hosting (SAAS)
7.  Informal arrangement (eg UIO linode)
Regardless of context, it is generally possible to make a reasonable plan (hosting in the basement is
 difficult), but many of the choices you make, eg virtualization technology, will be conditioned by the
material environment you will work within.  There are also significant cost and sustainability
 implications related to the material hosting environment.

### Division of (technical) labour

Implementations often require some degree of technical assistance to get started.  This ranges from 
public health specialists, DHIS2 configuration specialists through to backend technical support. The
focus of this document is on the latter, but some of the same issues are common.

A key question to be asked is how much technical assistance is required and for how long?  There is
an unfortunate history of people coming to setup a system and disappearing once project funds run out.
Or making themselves indispensable and available at consultancy rates which are not sustainable.  Backend workers are often invisible to managers, but they are required to keep the system running, 
up to date and secure. If self-reliance is an end goal in the project, then it needs to be planned for
accordingly.  Most importantly it involves identifying the people who will be responsible for system
administration and maintenance and engaging them in a long term skills development plan.  A project
plan which includes a one week handover period at the end is generally not effective as it
 under-estimates the nature and range of skills involved.  Plans which have resulted in a substantial
 level of self-reliance tend to:
 1.  involve the eventual administrators from the outset, through the planning, the installation, the
 mistakes, the debugging the reinstallation, the testing etc.
 2.  engage the administrators in a long term (at least two years) program of mentorship where they 
 gradually take greater control over their system, but with access to guidance, support and review.
 3.  create opportunities for further contact time during that period, perhaps once or twice a year.
 Having 3 weeks of contact time spread across two years is more effective than all at once.
 4.  provide opportunities for further skills development such as attendance of DHIS2 academies.
 5.  integrate the administrators into a broader community of practice where they can share experiences
 with peers.

Important things to consider when looking at developing capacity in this area are:
1.  The role of country/regional HISP teams. Often this is the best resource at hand and frequently they will have experience from a number of different country contexts.
2.  Developing specialists or jack-of-all-trades.  System administration is something of a specialist area.  Having the most technical person on the DHIS2 implementaion team dabble a little with servers might not be an adequate approach. Consider having at least two people specialise in this area. 
3.  The role of IT department within ministry vs vertical programs and HMIS.  This can be a tricky area involving local political concerns, but it should be more efficient, scalable and sustainable  to have
 backend support for DHIS2 (and other systems within the ministry) provided on an enterprise level 
 rather than each department/project attempting to control and manage the whole stack.
 