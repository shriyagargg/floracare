# ==========================================================
# FLORA CARE PRO - STREAMLIT APPLICATION
# Frontend + Backend + MySQL
# File Name: app.py
# Run Command: streamlit run app.py
# ==========================================================

import streamlit as st
import mysql.connector
import pandas as pd
from datetime import date, datetime

# ----------------------------------------------------------
# PAGE CONFIG
# ----------------------------------------------------------
st.set_page_config(
    page_title="Flora Care Pro",
    page_icon="🌿",
    layout="wide",
    initial_sidebar_state="expanded"
)

# ----------------------------------------------------------
# CUSTOM CSS
# ----------------------------------------------------------
st.markdown("""
<style>
/* ── App background ── */
.stApp {
    background: linear-gradient(135deg, #03170f, #072a1d, #03170f);
    color: white;
}

/* ── Sidebar ── */
section[data-testid="stSidebar"] {
    background: #071c13;
}

/* ── Headings ── */
h1, h2, h3 {
    color: white !important;
}

/* ── Metric cards ── */
.metric-card {
    background: linear-gradient(135deg, #0d3c27, #14653f);
    padding: 20px 16px;
    border-radius: 18px;
    text-align: center;
    margin-bottom: 15px;
    box-shadow: 0 4px 15px rgba(0, 0, 0, 0.3);
}
.metric-card h2 {
    font-size: 2rem;
    margin: 0 0 4px 0;
}
.metric-card p {
    margin: 0;
    font-size: 0.9rem;
    opacity: 0.85;
}

/* ── Content boxes ── */
.box {
    background: rgba(255, 255, 255, 0.05);
    padding: 20px;
    border-radius: 18px;
    margin-bottom: 15px;
}

/* ── Buttons ── */
.stButton > button {
    background: #1fe46e;
    color: black;
    font-weight: bold;
    border: none;
    border-radius: 12px;
    padding: 8px 20px;
    transition: background 0.2s ease;
}
.stButton > button:hover {
    background: #17c45c;
    color: black;
}

/* ── DataFrames ── */
.stDataFrame {
    border-radius: 15px;
}
</style>
""", unsafe_allow_html=True)


# ----------------------------------------------------------
# DATABASE CONNECTION  (cached so it is created only once)
# ----------------------------------------------------------
@st.cache_resource
def get_connection():
    try:
        conn = mysql.connector.connect(
            host="localhost",
            user="root",
            password="sg123456_",
            database="floracare"
        )
        return conn
    except mysql.connector.Error as err:
        st.error(f"Database connection failed: {err}")
        st.stop()


db = get_connection()


def run_query(query: str, params: tuple = ()) -> list:
    """Execute a SELECT query and return all rows."""
    cursor = db.cursor()
    cursor.execute(query, params)
    rows = cursor.fetchall()
    cursor.close()
    return rows


def run_insert(query: str, params: tuple) -> None:
    """Execute an INSERT / UPDATE query and commit."""
    cursor = db.cursor()
    cursor.execute(query, params)
    db.commit()
    cursor.close()


def call_procedure(proc_name: str, params: list) -> list:
    """Call a stored procedure and return results."""
    cursor = db.cursor()
    cursor.callproc(proc_name, params)
    results = []
    for result in cursor.stored_results():
        results.extend(result.fetchall())
    cursor.close()
    return results


# ----------------------------------------------------------
# TITLE
# ----------------------------------------------------------
st.title("🌿 Flora Care Pro")
st.caption("Smart Plant Wellness Management System")

# ----------------------------------------------------------
# SIDEBAR NAVIGATION
# ----------------------------------------------------------
menu = st.sidebar.radio(
    "Navigation",
    [
        "🏠 Dashboard",
        "👤 Users",
        "🌿 Species",
        "🌱 Plants",
        "📋 Tasks",
        "📝 Plant Logs",                        
        "🔔 Reminders",
        "🩺 Disease Reports",
        "🌍 Community",
        "🏆 Achievements",
        "📊 Reports",
        "🔬 Advanced Analytics",
    ],
)


# ==========================================================
# DASHBOARD
# ==========================================================
if menu == "🏠 Dashboard":

    users  = run_query("SELECT COUNT(*) FROM users")[0][0]
    plants = run_query("SELECT COUNT(*) FROM plants")[0][0]
    tasks  = run_query("SELECT COUNT(*) FROM care_tasks WHERE status='Pending'")[0][0]
    posts  = run_query("SELECT COUNT(*) FROM community_posts")[0][0]

    c1, c2, c3, c4 = st.columns(4)
    for col, value, label in zip(
        [c1, c2, c3, c4],
        [users, plants, tasks, posts],
        ["Users", "Plants", "Pending Tasks", "Posts"],
    ):
        with col:
            st.markdown(
                f"<div class='metric-card'><h2>{value}</h2><p>{label}</p></div>",
                unsafe_allow_html=True,
            )

    st.subheader("⚠️ Low Health Plants (score < 85)")
    rows = run_query("SELECT plant_name, health_score FROM plants WHERE health_score < 85")
    if rows:
        df = pd.DataFrame(rows, columns=["Plant Name", "Health Score"])
        st.dataframe(df, use_container_width=True)
    else:
        st.info("All plants are healthy! 🎉")


# ==========================================================
# USERS
# ==========================================================
elif menu == "👤 Users":

    st.subheader("Add User")

    with st.form("add_user_form", clear_on_submit=True):
        name     = st.text_input("Name")
        email    = st.text_input("Email")
        password = st.text_input("Password", type="password")
        city     = st.text_input("City")
        submitted = st.form_submit_button("Add User")

    if submitted:
        if not all([name, email, password, city]):
            st.warning("Please fill in all fields.")
        else:
            run_insert(
                "INSERT INTO users (name, email, password, city) VALUES (%s, %s, %s, %s)",
                (name, email, password, city),
            )
            st.success(f"User **{name}** added successfully.")

    st.subheader("All Users")
    rows = run_query("SELECT user_id, name, email, city FROM users")
    df = pd.DataFrame(rows, columns=["ID", "Name", "Email", "City"])
    st.dataframe(df, use_container_width=True)


# ==========================================================
# SPECIES
# ==========================================================
elif menu == "🌿 Species":

    st.subheader("Add Plant Species")

    with st.form("add_species_form", clear_on_submit=True):
        species  = st.text_input("Species Name")
        sunlight = st.text_input("Sunlight Need")
        water    = st.number_input("Watering Frequency (Days)", min_value=1, step=1)
        toxicity = st.selectbox("Toxicity Level", ["None", "Low", "Medium", "High"])
        submitted = st.form_submit_button("Add Species")

    if submitted:
        if not all([species, sunlight]):
            st.warning("Please fill in all fields.")
        else:
            run_insert(
                "INSERT INTO species (species_name, sunlight_need, watering_frequency, toxicity_level) VALUES (%s, %s, %s, %s)",
                (species, sunlight, water, toxicity),
            )
            st.success(f"Species **{species}** added successfully.")

    st.subheader("All Species")
    rows = run_query("SELECT * FROM species")
    df = pd.DataFrame(rows, columns=["ID", "Species", "Sunlight", "Watering (Days)", "Toxicity"])
    st.dataframe(df, use_container_width=True)


# ==========================================================
# PLANTS
# ==========================================================
elif menu == "🌱 Plants":

    st.subheader("Add Plant")

    with st.form("add_plant_form", clear_on_submit=True):
        user_id    = st.number_input("User ID", min_value=1, step=1)
        species_id = st.number_input("Species ID", min_value=1, step=1)
        plant      = st.text_input("Plant Name")
        age        = st.number_input("Age (Months)", min_value=0, step=1)
        location   = st.selectbox("Location", ["Indoor", "Outdoor", "Balcony", "Terrace"])
        submitted  = st.form_submit_button("Add Plant")

    if submitted:
        if not plant:
            st.warning("Please enter a plant name.")
        else:
            run_insert(
                "INSERT INTO plants (user_id, species_id, plant_name, age_months, location) VALUES (%s, %s, %s, %s, %s)",
                (user_id, species_id, plant, age, location),
            )
            st.success(f"Plant **{plant}** added successfully.")

    st.subheader("All Plants")
    rows = run_query("SELECT plant_id, plant_name, location, health_score FROM plants")
    df = pd.DataFrame(rows, columns=["ID", "Plant", "Location", "Health Score"])
    st.dataframe(df, use_container_width=True)


# ==========================================================
# TASKS
# ==========================================================
elif menu == "📋 Tasks":

    st.subheader("Create Care Task")

    with st.form("add_task_form", clear_on_submit=True):
        plant_id  = st.number_input("Plant ID", min_value=1, step=1)
        task      = st.text_input("Task Type")
        due       = st.date_input("Due Date", date.today())
        submitted = st.form_submit_button("Add Task")

    if submitted:
        if not task:
            st.warning("Please enter a task type.")
        else:
            run_insert(
                "INSERT INTO care_tasks (plant_id, task_type, due_date, status) VALUES (%s, %s, %s, %s)",
                (plant_id, task, due, "Pending"),
            )
            st.success("Task added successfully.")

    st.subheader("All Tasks")
    rows = run_query("SELECT task_id, plant_id, task_type, due_date, status FROM care_tasks")
    df = pd.DataFrame(rows, columns=["ID", "Plant ID", "Task", "Due Date", "Status"])
    st.dataframe(df, use_container_width=True)


# ==========================================================
# PLANT LOGS
# ==========================================================
elif menu == "📝 Plant Logs":

    st.subheader("Add Plant Log")

    with st.form("add_log_form", clear_on_submit=True):
        plant_id  = st.number_input("Plant ID", min_value=1, step=1)
        action    = st.text_input("Action Taken")
        notes     = st.text_area("Notes")
        log_date  = st.date_input("Date", date.today())
        submitted = st.form_submit_button("Add Log")

    if submitted:
        if not action:
            st.warning("Please describe the action taken.")
        else:
            run_insert(
                "INSERT INTO plant_logs (plant_id, action_taken, notes, log_date) VALUES (%s, %s, %s, %s)",
                (plant_id, action, notes, log_date),
            )
            st.success("Log added successfully.")

    st.subheader("All Logs")
    rows = run_query("SELECT log_id, plant_id, action_taken, log_date FROM plant_logs")
    df = pd.DataFrame(rows, columns=["ID", "Plant ID", "Action", "Date"])
    st.dataframe(df, use_container_width=True)


# ==========================================================
# REMINDERS
# ==========================================================
elif menu == "🔔 Reminders":

    st.subheader("Create Reminder")

    with st.form("add_reminder_form", clear_on_submit=True):
        user_id   = st.number_input("User ID", min_value=1, step=1)
        plant_id  = st.number_input("Plant ID", min_value=1, step=1)
        rtype     = st.text_input("Reminder Type")
        rdate     = st.date_input("Reminder Date", date.today())
        rtime     = st.time_input("Reminder Time", value=datetime.now().time().replace(second=0, microsecond=0))
        submitted = st.form_submit_button("Add Reminder")

    if submitted:
        if not rtype:
            st.warning("Please enter a reminder type.")
        else:
            reminder_dt = datetime.combine(rdate, rtime)
            run_insert(
                "INSERT INTO reminders (user_id, plant_id, reminder_type, reminder_time, active) VALUES (%s, %s, %s, %s, %s)",
                (user_id, plant_id, rtype, reminder_dt, 1),
            )
            st.success("Reminder added successfully.")

    st.subheader("All Reminders")
    rows = run_query("SELECT reminder_id, reminder_type, reminder_time, active FROM reminders")
    df = pd.DataFrame(rows, columns=["ID", "Type", "Time", "Active"])
    st.dataframe(df, use_container_width=True)


# ==========================================================
# DISEASE REPORTS
# ==========================================================
elif menu == "🩺 Disease Reports":

    st.subheader("Add Disease Report")

    with st.form("add_disease_form", clear_on_submit=True):
        plant_id  = st.number_input("Plant ID", min_value=1, step=1)
        symptom   = st.text_input("Symptom")
        diagnosis = st.text_input("Diagnosis")
        severity  = st.selectbox("Severity", ["Low", "Medium", "High"])
        submitted = st.form_submit_button("Add Report")

    if submitted:
        if not all([symptom, diagnosis]):
            st.warning("Please fill in symptom and diagnosis.")
        else:
            run_insert(
                "INSERT INTO disease_reports (plant_id, symptom, diagnosis, severity) VALUES (%s, %s, %s, %s)",
                (plant_id, symptom, diagnosis, severity),
            )
            st.success("Disease report added successfully.")

    st.subheader("All Disease Reports")
    rows = run_query("SELECT report_id, symptom, diagnosis, severity FROM disease_reports")
    df = pd.DataFrame(rows, columns=["ID", "Symptom", "Diagnosis", "Severity"])
    st.dataframe(df, use_container_width=True)


# ==========================================================
# COMMUNITY
# ==========================================================
elif menu == "🌍 Community":

    st.subheader("Create Community Post")

    with st.form("add_post_form", clear_on_submit=True):
        user_id   = st.number_input("User ID", min_value=1, step=1)
        title     = st.text_input("Post Title")
        content   = st.text_area("Content")
        submitted = st.form_submit_button("Post")

    if submitted:
        if not all([title, content]):
            st.warning("Please fill in the title and content.")
        else:
            run_insert(
                "INSERT INTO community_posts (user_id, title, content) VALUES (%s, %s, %s)",
                (user_id, title, content),
            )
            st.success("Post published successfully.")

    st.subheader("Recent Posts")
    rows = run_query("SELECT title, likes FROM community_posts ORDER BY post_id DESC")
    df = pd.DataFrame(rows, columns=["Post Title", "Likes"])
    st.dataframe(df, use_container_width=True)


# ==========================================================
# ACHIEVEMENTS
# ==========================================================
elif menu == "🏆 Achievements":

    st.subheader("Add Achievement")

    with st.form("add_achievement_form", clear_on_submit=True):
        user_id   = st.number_input("User ID", min_value=1, step=1)
        badge     = st.text_input("Badge Name")
        earned    = st.date_input("Earned Date", date.today())
        submitted = st.form_submit_button("Add Badge")

    if submitted:
        if not badge:
            st.warning("Please enter a badge name.")
        else:
            run_insert(
                "INSERT INTO achievements (user_id, badge_name, earned_on) VALUES (%s, %s, %s)",
                (user_id, badge, earned),
            )
            st.success(f"Badge **{badge}** added successfully.")

    st.subheader("All Achievements")
    rows = run_query("SELECT badge_name, earned_on FROM achievements")
    df = pd.DataFrame(rows, columns=["Badge", "Earned On"])
    st.dataframe(df, use_container_width=True)


# ==========================================================
# REPORTS
# ==========================================================
elif menu == "📊 Reports":

    # ── Plants by Location ──────────────────────────────────
    st.subheader("Plants by Location")
    rows = run_query("SELECT location, COUNT(*) FROM plants GROUP BY location")
    if rows:
        df_loc = pd.DataFrame(rows, columns=["Location", "Count"])
        st.dataframe(df_loc, use_container_width=True)
        st.bar_chart(df_loc.set_index("Location"))
    else:
        st.info("No plant data available.")

    st.divider()

    # ── Average Health Score ────────────────────────────────
    st.subheader("Average Health Score")
    result = run_query("SELECT AVG(health_score) FROM plants")
    avg = result[0][0]
    if avg is not None:
        st.success(f"Average Plant Health: **{round(avg, 2)}%**")
    else:
        st.info("No health data available.")

    st.divider()

    # ── Users with Plant Count ──────────────────────────────
    st.subheader("Users with Plant Count")
    rows = run_query("""
        SELECT u.name, COUNT(p.plant_id)
        FROM users u
        LEFT JOIN plants p ON u.user_id = p.user_id
        GROUP BY u.name
    """)
    df_users = pd.DataFrame(rows, columns=["User", "Total Plants"])
    st.dataframe(df_users, use_container_width=True)


# ==========================================================
# ADVANCED ANALYTICS (Views, Procedures, Functions)
# ==========================================================
elif menu == "🔬 Advanced Analytics":

    st.header("Advanced Analytics & Database Operations")
    
    tab1, tab2, tab3, tab4 = st.tabs(["📊 Views", "⚙️ Procedures", "🔧 Functions", "🎯 Custom Queries"])
    
    # ═══════════════════════════════════════════════════════
    # TAB 1: VIEWS
    # ═══════════════════════════════════════════════════════
    with tab1:
        st.subheader("Database Views")
        
        view_option = st.selectbox(
            "Select a View",
            [
                "Plant Profile (Complete Details)",
                "Critical Plants (Health < 70)",
                "Overdue Tasks",
                "User Dashboard Summary",
                "Disease Summary",
                "Popular Posts (Likes > 5)",
                "Species Ranking",
                "Today's Reminders"
            ]
        )
        
        if view_option == "Plant Profile (Complete Details)":
            st.info("Shows complete plant information with owner and species details")
            rows = run_query("SELECT * FROM view_plant_profile")
            if rows:
                df = pd.DataFrame(rows, columns=[
                    "Plant ID", "Plant Name", "User ID", "Owner", "Email", "City",
                    "Species", "Sunlight", "Watering Freq", "Toxicity", "Age (months)",
                    "Location", "Health Score", "Health Status"
                ])
                st.dataframe(df, use_container_width=True)
            else:
                st.warning("No data available")
        
        elif view_option == "Critical Plants (Health < 70)":
            st.warning("Plants that need immediate attention")
            rows = run_query("SELECT * FROM view_critical_plants")
            if rows:
                df = pd.DataFrame(rows, columns=["Plant ID", "Plant Name", "Owner", "Email", "Health Score", "Location"])
                st.dataframe(df, use_container_width=True)
            else:
                st.success("No critical plants! All are healthy 🎉")
        
        elif view_option == "Overdue Tasks":
            st.error("Tasks that are past their due date")
            rows = run_query("SELECT * FROM view_overdue_tasks")
            if rows:
                df = pd.DataFrame(rows, columns=["Task ID", "Plant Name", "Owner", "Email", "Task Type", "Due Date", "Days Overdue"])
                st.dataframe(df, use_container_width=True)
            else:
                st.success("No overdue tasks! 👍")
        
        elif view_option == "User Dashboard Summary":
            st.info("Complete user activity summary")
            rows = run_query("SELECT * FROM view_user_dashboard")
            if rows:
                df = pd.DataFrame(rows, columns=[
                    "User ID", "Name", "City", "Total Plants", "Avg Health",
                    "Pending Tasks", "Total Posts", "Badges Earned"
                ])
                st.dataframe(df, use_container_width=True)
            else:
                st.warning("No users found")
        
        elif view_option == "Disease Summary":
            st.info("Disease outbreak analysis")
            rows = run_query("SELECT * FROM view_disease_summary")
            if rows:
                df = pd.DataFrame(rows, columns=["Diagnosis", "Severity", "Case Count", "Affected Plants"])
                st.dataframe(df, use_container_width=True)
            else:
                st.success("No disease reports")
        
        elif view_option == "Popular Posts (Likes > 5)":
            st.info("Community posts with more than 5 likes")
            rows = run_query("SELECT * FROM view_popular_posts")
            if rows:
                df = pd.DataFrame(rows, columns=["Post ID", "Author", "Title", "Likes", "Preview"])
                st.dataframe(df, use_container_width=True)
            else:
                st.info("No popular posts yet")
        
        elif view_option == "Species Ranking":
            st.info("Most popular plant species")
            rows = run_query("SELECT * FROM view_species_ranking")
            if rows:
                df = pd.DataFrame(rows, columns=[
                    "Species ID", "Species Name", "Plant Count", "Avg Health",
                    "Sunlight Need", "Watering Frequency"
                ])
                st.dataframe(df, use_container_width=True)
                st.bar_chart(df.set_index("Species Name")["Plant Count"])
            else:
                st.warning("No species data")
        
        elif view_option == "Today's Reminders":
            st.info("Active reminders scheduled for today")
            rows = run_query("SELECT * FROM view_todays_reminders")
            if rows:
                df = pd.DataFrame(rows, columns=["Reminder ID", "User Name", "Email", "Plant Name", "Reminder Type", "Reminder Time"])
                st.dataframe(df, use_container_width=True)
            else:
                st.info("No reminders for today")
    
    # ═══════════════════════════════════════════════════════
    # TAB 2: STORED PROCEDURES
    # ═══════════════════════════════════════════════════════
    with tab2:
        st.subheader("Execute Stored Procedures")
        
        proc_option = st.selectbox(
            "Select a Procedure",
            [
                "Register New User",
                "Add Plant with Auto Task",
                "Complete Task & Log",
                "Update Health with Alert",
                "Get User Report",
                "Award Badge"
            ]
        )
        
        if proc_option == "Register New User":
            st.info("Register a new user with email validation")
            with st.form("register_user_proc"):
                name = st.text_input("Name")
                email = st.text_input("Email")
                password = st.text_input("Password", type="password")
                city = st.text_input("City")
                submit = st.form_submit_button("Register User")
            
            if submit and all([name, email, password, city]):
                cursor = db.cursor()
                cursor.callproc('RegisterUser', [name, email, password, city])
                for result in cursor.stored_results():
                    msg = result.fetchone()[0]
                    if "Error" in msg:
                        st.error(msg)
                    else:
                        st.success(msg)
                cursor.close()
        
        elif proc_option == "Add Plant with Auto Task":
            st.info("Add a plant and automatically create first watering task")
            with st.form("add_plant_proc"):
                user_id = st.number_input("User ID", min_value=1, step=1)
                species_id = st.number_input("Species ID", min_value=1, step=1)
                plant_name = st.text_input("Plant Name")
                age_months = st.number_input("Age (Months)", min_value=0, step=1)
                location = st.selectbox("Location", ["Indoor", "Outdoor", "Balcony", "Terrace"])
                submit = st.form_submit_button("Add Plant")
            
            if submit and plant_name:
                cursor = db.cursor()
                cursor.callproc('AddPlantWithTask', [user_id, species_id, plant_name, age_months, location])
                for result in cursor.stored_results():
                    st.success(result.fetchone()[0])
                cursor.close()
                db.commit()
        
        elif proc_option == "Complete Task & Log":
            st.info("Mark a task as completed and log the action")
            task_id = st.number_input("Task ID", min_value=1, step=1)
            if st.button("Complete Task"):
                cursor = db.cursor()
                cursor.callproc('CompleteTask', [task_id])
                for result in cursor.stored_results():
                    st.success(result.fetchone()[0])
                cursor.close()
                db.commit()
        
        elif proc_option == "Update Health with Alert":
            st.info("Update plant health score and create alert if critical")
            plant_id = st.number_input("Plant ID", min_value=1, step=1)
            new_health = st.slider("New Health Score", 0.0, 100.0, 80.0)
            if st.button("Update Health"):
                cursor = db.cursor()
                cursor.callproc('UpdateHealthWithAlert', [plant_id, new_health])
                for result in cursor.stored_results():
                    msg = result.fetchone()[0]
                    if "ALERT" in msg:
                        st.error(msg)
                    else:
                        st.success(msg)
                cursor.close()
                db.commit()
        
        elif proc_option == "Get User Report":
            st.info("Get complete report for a user")
            user_id = st.number_input("User ID", min_value=1, step=1)
            if st.button("Generate Report"):
                cursor = db.cursor()
                cursor.callproc('GetUserReport', [user_id])
                for result in cursor.stored_results():
                    data = result.fetchone()
                    if data:
                        col1, col2, col3, col4 = st.columns(4)
                        with col1:
                            st.metric("Name", data[0])
                        with col2:
                            st.metric("Total Plants", data[3])
                        with col3:
                            st.metric("Avg Health", f"{data[4]}%")
                        with col4:
                            st.metric("Badges", data[6])
                        st.info(f"📧 {data[1]} | 🏙️ {data[2]} | 📋 {data[5]} pending tasks")
                    else:
                        st.warning("User not found")
                cursor.close()
        
        elif proc_option == "Award Badge":
            st.info("Award an achievement badge to a user")
            with st.form("award_badge_proc"):
                user_id = st.number_input("User ID", min_value=1, step=1)
                badge_name = st.text_input("Badge Name")
                submit = st.form_submit_button("Award Badge")
            
            if submit and badge_name:
                cursor = db.cursor()
                cursor.callproc('AwardBadge', [user_id, badge_name])
                for result in cursor.stored_results():
                    st.success(result.fetchone()[0])
                cursor.close()
                db.commit()
    
    # ═══════════════════════════════════════════════════════
    # TAB 3: FUNCTIONS
    # ═══════════════════════════════════════════════════════
    with tab3:
        st.subheader("Database Functions")
        
        func_option = st.selectbox(
            "Select a Function",
            [
                "Plant Age in Years",
                "Health Status Label",
                "Count Pending Tasks",
                "Days Until Watering",
                "User Rank by Plants",
                "Needs Attention Check",
                "User Total Likes"
            ]
        )
        
        if func_option == "Plant Age in Years":
            st.info("Convert plant age from months to years")
            rows = run_query("""
                SELECT plant_id, plant_name, age_months, GetPlantAgeYears(plant_id) AS age_years
                FROM plants
            """)
            df = pd.DataFrame(rows, columns=["Plant ID", "Plant Name", "Age (Months)", "Age (Years)"])
            st.dataframe(df, use_container_width=True)
        
        elif func_option == "Health Status Label":
            st.info("Get health status label for all plants")
            rows = run_query("""
                SELECT plant_name, health_score, GetHealthLabel(health_score) AS health_status
                FROM plants
            """)
            df = pd.DataFrame(rows, columns=["Plant Name", "Health Score", "Health Status"])
            st.dataframe(df, use_container_width=True)
        
        elif func_option == "Count Pending Tasks":
            st.info("Count pending tasks for each plant")
            rows = run_query("""
                SELECT plant_id, plant_name, CountPendingTasks(plant_id) AS pending_tasks
                FROM plants
            """)
            df = pd.DataFrame(rows, columns=["Plant ID", "Plant Name", "Pending Tasks"])
            st.dataframe(df, use_container_width=True)
        
        elif func_option == "Days Until Watering":
            st.info("Days remaining until next watering (-1 means no task scheduled)")
            rows = run_query("""
                SELECT plant_id, plant_name, DaysUntilWatering(plant_id) AS days_to_water
                FROM plants
            """)
            df = pd.DataFrame(rows, columns=["Plant ID", "Plant Name", "Days Until Watering"])
            st.dataframe(df, use_container_width=True)
        
        elif func_option == "User Rank by Plants":
            st.info("User ranking based on number of plants owned")
            rows = run_query("""
                SELECT user_id, name, GetUserRank(user_id) AS rank
                FROM users
                ORDER BY rank
            """)
            df = pd.DataFrame(rows, columns=["User ID", "Name", "Rank"])
            st.dataframe(df, use_container_width=True)
        
        elif func_option == "Needs Attention Check":
            st.info("Check which plants need immediate attention")
            rows = run_query("""
                SELECT plant_id, plant_name, health_score, NeedsAttention(plant_id) AS needs_attention
                FROM plants
            """)
            df = pd.DataFrame(rows, columns=["Plant ID", "Plant Name", "Health Score", "Needs Attention"])
            st.dataframe(df, use_container_width=True)
        
        elif func_option == "User Total Likes":
            st.info("Total likes received by each user on their posts")
            rows = run_query("""
                SELECT user_id, name, GetUserTotalLikes(user_id) AS total_likes
                FROM users
            """)
            df = pd.DataFrame(rows, columns=["User ID", "Name", "Total Likes"])
            st.dataframe(df, use_container_width=True)
    
    # ═══════════════════════════════════════════════════════
    # TAB 4: CUSTOM QUERIES
    # ═══════════════════════════════════════════════════════
    with tab4:
        st.subheader("Run Custom SQL Queries")
        st.warning("⚠️ Be careful! Only SELECT queries are recommended.")
        
        query = st.text_area("Enter SQL Query", height=150, placeholder="SELECT * FROM plants WHERE health_score > 80")
        
        if st.button("Execute Query"):
            if query.strip():
                try:
                    rows = run_query(query)
                    if rows:
                        # Auto-detect column count
                        col_count = len(rows[0])
                        columns = [f"Column_{i+1}" for i in range(col_count)]
                        df = pd.DataFrame(rows, columns=columns)
                        st.success(f"Query returned {len(rows)} rows")
                        st.dataframe(df, use_container_width=True)
                    else:
                        st.info("Query executed successfully but returned no rows")
                except Exception as e:
                    st.error(f"Error: {str(e)}")
            else:
                st.warning("Please enter a query")
