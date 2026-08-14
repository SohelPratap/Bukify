import pool from "../config/db.js";


/**
 * SEARCH SKILLS (autocomplete)
 * GET /api/skills/search?q=plumb
 */
export const searchSkills = async (req, res) => {
  try {

    const query = req.query.q;

    if (!query || query.length < 1) {
      return res.json([]);
    }

    const [rows] = await pool.execute(
      `SELECT id, name
       FROM skills
       WHERE name LIKE ?
       ORDER BY name ASC
       LIMIT 10`,
      [`%${query}%`]
    );

    res.json(rows);

  } catch (error) {

    console.error("Skill search error:", error);

    res.status(500).json({
      message: "Server error"
    });

  }
};




/**
 * ADD SKILL
 * POST /api/skills/add
 */
export const addSkill = async (req, res) => {

  try {

    const workerId = req.user.userId; // comes from JWT
    const { skill_id } = req.body;

    if (!skill_id) {

      return res.status(400).json({
        message: "skill_id required"
      });

    }

    /// CHECK DUPLICATE
    const [exists] = await pool.execute(

      `SELECT id
       FROM worker_skills
       WHERE worker_id = ?
       AND skill_id = ?`,

      [workerId, skill_id]

    );

    if (exists.length > 0) {

      return res.json({
        message: "Skill already added"
      });

    }


    /// INSERT SKILL
    await pool.execute(

      `INSERT INTO worker_skills
       (id, worker_id, skill_id, status)
       VALUES (UUID(), ?, ?, 'pending')`,

      [workerId, skill_id]

    );

    res.json({
      message: "Skill added successfully",
      status: "pending"
    });

  } catch (err) {

    console.error("Add skill error:", err);

    res.status(500).json({
      error: err.message
    });

  }
};




/**
 * GET MY SKILLS
 * GET /api/skills/my
 */
export const getMySkills = async (req, res) => {

  try {

    const workerId = req.user.userId;

    const [rows] = await pool.execute(

      `SELECT
        s.id,
        s.name,
        ws.status,
        ws.created_at,
        ws.verified_at
       FROM worker_skills ws
       JOIN skills s
       ON ws.skill_id = s.id
       WHERE ws.worker_id = ?
       ORDER BY ws.created_at DESC`,

      [workerId]

    );

    res.json(rows);

  } catch (err) {

    console.error("Get skills error:", err);

    res.status(500).json({
      error: err.message
    });

  }
};
/**
 * REMOVE SKILL
 * DELETE /api/skills/remove/:skill_id
 */
export const removeSkill = async (req, res) => {

  try {

    const workerId = req.user.userId;
    const skillId = req.params.skill_id;

    await pool.execute(

      `DELETE FROM worker_skills
       WHERE worker_id = ?
       AND skill_id = ?`,

      [workerId, skillId]

    );

    res.json({
      message: "Skill removed"
    });

  }
  catch (err) {

    console.error(err);

    res.status(500).json({
      error: err.message
    });

  }
};


export const getAllSkills = async (req, res) => {
  try {

    const [rows] = await pool.execute(
      `SELECT id, name
       FROM skills
       ORDER BY name ASC`
    );

    res.json(rows);

  } catch (error) {

    console.error("Get all skills error:", error);

    res.status(500).json({
      message: "Server error"
    });

  }
};