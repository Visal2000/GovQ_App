import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";

const firebaseConfig = {
  apiKey: "AIzaSyBIaPSEk3nsZRrWo0xjbg3OXlTLuXoqqDk",
  authDomain: "govq-d6d0c.firebaseapp.com",
  projectId: "govq-d6d0c",
  storageBucket: "govq-d6d0c.firebasestorage.app",
  messagingSenderId: "712217903276",
  appId: "1:712217903276:web:faf5abcb309f76e181df09",
  measurementId: "G-81RQ01H4P5"
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
